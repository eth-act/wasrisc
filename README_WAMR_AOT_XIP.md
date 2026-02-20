# Running WAMR AOT with XIP on ZisK

## The Target Platform and Its Memory Model

ZisK is a zero-knowledge virtual machine with a strict separation of memory into two regions:

- **ROM (executable, read-only):** mapped at `0x80000000`, 256 MB. Code can be fetched and executed from here, but the region cannot be written.
- **RAM (readable, writable):** mapped at `0xa0020000`. Data lives here, but this region is not executable.

This is a variant of the **Harvard architecture** — or more precisely, a *modified Harvard* architecture where the address spaces are unified (you can read data from ROM using load instructions), but write access to the executable region is prohibited. Unlike a pure von Neumann machine where code and data share a single read-write memory, here the executable region is permanently read-only.

The key constraint that follows: **nothing that lands in ROM can be patched at runtime**. No self-modifying code, no relocation fixups, no runtime writes to the text section. Whatever ends up in ROM must be complete and self-consistent before execution begins.

## Caution!

The attempts to read code as data weren't successful yet on Zisk. The investigation of that is in progress. From now on let's assume that Zisk indeed is capable of reading code as data.

---

## Standard WAMR AOT and Why It Doesn't Fit

WAMR's normal AOT workflow compiles a `.wasm` file into a native `.aot` binary using `wamrc`. The resulting file contains machine code that the WAMR runtime loads into memory and executes. On a general-purpose OS, "loading" means:

1. Copying the AOT file's sections into memory regions with the right permissions.
2. Applying **relocations** — patches to the loaded code that fix up addresses of functions and data that are not known until load time.

Relocations are the crux of the problem. A standard AOT file contains a `.rela.text` section that lists addresses inside the code that need to be rewritten before execution. The WAMR AOT loader walks this table at startup and patches the code in-place. On a von Neumann machine with writable executable memory this is routine. On our platform, it is impossible: the code lives in ROM, and writing to ROM is not allowed.

---

## XIP: The Intended Solution

WAMR provides the **XIP (Execution In Place)** feature precisely for this class of platform (see the [official XIP documentation](https://wamr.gitbook.io/document/wamr-in-practice/features/xip)). Enabling it is as simple as passing a single flag to `wamrc`:

```
--xip
```

This is shorthand for two underlying flags — `--enable-indirect-mode` and `--disable-llvm-intrinsics` — each of which eliminates a distinct class of relocations.

The two mechanisms it activates:

**Indirect mode** eliminates relocations caused by direct function calls. In a normal AOT binary, when function A calls function B, LLVM emits a direct call instruction whose target address is filled in by a relocation at load time. With indirect mode enabled, functions do not call each other directly. Instead, every function receives a pointer to a *function pointer table* (carried in the `exec_env` argument), and calls go through that table. The table itself lives in RAM and is populated by the runtime at startup — so the code in ROM never needs to be patched for function calls.

**Disabling LLVM intrinsics** eliminates another class of relocations: calls from AOT code to LLVM's built-in helper functions (intrinsics for operations like integer overflow, memory copy, etc.). With this flag, WAMR substitutes its own runtime-implemented versions of these helpers, again accessed through the function pointer table, avoiding any direct call relocations.

The WAMR documentation itself acknowledges the remaining gap:

> *"There may be some relocations to the `.rodata` like sections which require to patch the AOT code. More work will be done to resolve it in the future."*

And indeed, after enabling `--xip`, compiling a Go-compiled WebAssembly module still produced many relocations in `.rela.text`.

---

## Why Relocations Persisted: The Constant Pool

Inspecting the relocations revealed that all of them were of the same kind:

```
R_RISCV_PCREL_HI20  →  .LCPIxx_0
R_RISCV_PCREL_LO12_I
```

These are **not** function call relocations — `--xip` had successfully eliminated those. These are references from `.text` into `.rodata.cst8`: LLVM's **constant pool** for 8-byte constants that cannot be encoded as immediates.

On RISC-V, there is no instruction encoding that allows an arbitrary 64-bit constant to be embedded directly in the instruction stream. When LLVM encounters such a constant — whether a floating-point value like `0x7FF0000000000000` (IEEE 754 positive infinity) or any other 8-byte value that cannot be materialized via `lui`/`addi` sequences — it has no choice but to store it in a read-only data section (`.rodata.cst8`) and emit a PC-relative load pair to fetch it at runtime:

```asm
auipc  a0, %pcrel_hi(.LCPI84_0)         ; R_RISCV_PCREL_HI20 relocation
fld    fa0, %pcrel_lo(.Lpcrel_hi0)(a0)  ; R_RISCV_PCREL_LO12 relocation
```

Because the final address of `.rodata.cst8` relative to `.text` is not known at compile time (it depends on where the linker places each section), LLVM emits relocations so the loader can patch the `auipc`/`fld` pair with the correct offset. The wasm module in question was compiled from Go and contained a large number of such constants, resulting in many constant pool entries.

The constants originate in the WebAssembly module itself, faithfully translated into LLVM IR by WAMR, and the RISC-V backend has no other way to handle them — none of the standard `wamrc` options address this class of relocation.

---

## The Fix: Forcing Inline Constant Materialization

The solution was found by querying the hidden LLVM option list:

```bash
echo "" | clang -x c - -mllvm -help-list-hidden 2>&1 | grep -i "const\|pool"
```

Among the results was a RISC-V-specific flag:

```
--riscv-disable-using-constant-pool-for-large-ints
```

Despite its name referencing "integers", the flag covers the full range of 8-byte constants that the RISC-V backend would otherwise spill to a constant pool. Disabling the constant pool forces LLVM to materialize every constant inline using integer instruction sequences — typically `lui` + `addi` + `slli` chains to build the bit pattern. The result is slightly larger code, but **zero references to `.rodata.cst8`** and therefore **zero relocations**.

The final working `wamrc` invocation:

```bash
wamrc --xip \
  --target=riscv64 \
  --target-abi=lp64 \
  --cpu=generic-rv64 \
  --cpu-features='+i,+m,+a' \
  --mllvm=-riscv-disable-using-constant-pool-for-large-ints \
  --opt-level=0 \
  --size-level=1 \
  --bounds-checks=0 \
  -o wamr.xip.aot \
  examples/build-wasm/go/stateless.wasm
```

Verification:

```bash
readelf -r wamr.xip.aot | grep -c RISCV
# → 0
```

---

## A Word of Caution: This Is Not Guaranteed

It is worth being explicit about the limits of this approach. The `--xip` flag eliminates function-call relocations by design. The `--riscv-disable-using-constant-pool-for-large-ints` flag eliminates constant pool relocations for this particular wasm module on this particular LLVM version. But **there is no architectural guarantee that no other source of text relocations can arise**.

The WAMR project's own history illustrates this vividly. A sample issue that have appeared over time is [RISC-V: avoid `llvm.cttz.i32/i64` for XIP](https://github.com/bytecodealliance/wasm-micro-runtime/pull/4248). More issues of this type have occured in the past.

Each of these was a case where some code pattern — NaN constants, specific intrinsics, or data layout decisions — caused LLVM to emit a structure that produced text relocations despite `--xip` being set. They were discovered and fixed one by one, and the pattern is ongoing.

The implication is that if your wasm module uses language features or patterns not yet encountered by the WAMR developers on your target architecture, new relocation-generating patterns could surface. The correct engineering response is to always verify the output:

```bash
readelf -r your_output.aot
```

and treat any entry in `.rela.text` as a blocker before deploying to a read-only execution platform.

---

## Linker Script: Placing `.rodata` in ROM

With zero text relocations confirmed, the AOT file can be linked into the ZisK firmware image. The critical insight for the linker script is that `.rodata` must be placed in the **ROM region** alongside `.text`.

The reason is how the AOT module is embedded in the host C program: the compiled `.aot` file is included as a `const char[]` array. Being `const`, the linker places it in `.rodata`, which in turn lands in ROM. When the WAMR runtime receives a pointer to this array and transfers control into it, the code it begins executing is already in ROM — exactly where it needs to be. There is no copy, no allocation, no load step: the module executes in place directly from the ROM-resident `const` buffer.

This means `.rodata` and `.text` must share the same executable, read-only region:

```ld
MEMORY {
  rom   (xa) : ORIGIN = 0x80000000, LENGTH = 0x10000000
  ram   (wxa) : ORIGIN = 0xa0020000, LENGTH = 0x1FFE0000
}

SECTIONS {
  .text   : { *(.text.init) *(.text .text.*) } >rom AT>rom :text

  . = ALIGN(8);
  .rodata : { *(.rodata .rodata.* .srodata .srodata.*) } >rom AT>rom :rodata

  .data   : { *(.data .data.*) }  >ram AT>ram :data
  .bss    : { *(.bss  .bss.*)  }  >ram AT>ram :bss
}
```

---

## Memory Architecture Requirements and the von Neumann / Harvard Distinction

This setup clarifies the minimal memory architecture requirements for using WAMR AOT with XIP on an embedded platform.

**Pure Harvard architecture** — completely separate instruction memory and data memory with no overlap — would actually make XIP *impossible* in the general case. The WAMR AOT file is a data structure that the runtime parses before executing. The runtime needs to *read* the AOT binary as data (to extract metadata, function table entries, etc.) before jumping into it as code. A pure Harvard machine where the CPU cannot issue data-load instructions against the instruction memory would prevent this.

**ZisK is modified Harvard**: there is a single address space, but the ROM region has attributes of `(xa)` — executable and readable as data, but not writable. This is exactly the right model. The CPU can:
- Execute instructions fetched from ROM (the `.text` section of the AOT file).
- Load data from ROM using ordinary load instructions (reading `.rodata`, string tables, the AOT header, etc.).
- Write to RAM freely (stack, heap, WASM linear memory, and the function pointer table used by indirect-mode calls).

The minimal architectural requirements for XIP WAMR AOT can therefore be stated as:

1. **A region that is executable and readable as data, but not writable.** This is where `.text` and `.rodata` of the AOT file are placed. "Readable as data" is mandatory — the WAMR runtime must be able to parse the AOT binary's metadata from the same buffer it will later execute.

2. **A region that is readable and writable (but need not be executable).** This is where the WAMR runtime itself can operate: heap, stack, WASM linear memory, and the function pointer table that makes indirect mode work.

3. **Zero text relocations in the AOT file.** Any relocation targeting the text/rodata region would require a write to the read-only region at load time, which is impossible. This must be verified explicitly after compilation.

A pure von Neumann machine (single unified read-write-execute memory) trivially satisfies all these requirements but provides no protection. A pure Harvard machine fails requirement 1 (cannot read instruction memory as data). The modified Harvard model — as present in ZisK and many other architectures with separate permission attributes for executable and writable regions — is precisely the architecture class that WAMR XIP can run on, assuming no relocations are present in AOT file.
