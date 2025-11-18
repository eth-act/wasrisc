# WASRISC

This repository contains a toolchain for transpiling WASM-WASI programs to run on bare metal RISC-V targets. The main target for this repository are RISCV zkVMs. One can think of this target as a very limited virtual CPU.

Note: Any language that compiles to WASM with WASI support(0.1) can use this pipeline

## Pipeline Overview

```
Source Code (Go, Rust, C, Zig, etc.)
    ↓ (Language-specific WASM compiler)
WebAssembly with WASI (wasip1)
    ↓ (w2c2 transpiler)
C Source Code
    ↓ (GCC/platform-specific compiler)
Target Binary (zkVM/RISC-V/AMD64)
```

## Prerequisites

The easiest way to build is using the provided Docker environment, which includes:

- RISC-V GNU Toolchain with newlib (rv64ima)
- w2c2 WebAssembly-to-C transpiler

> Running the docker script the first time, will take some time because it is rebuilding the RISCV gnu toolchain from source inside of Docker.

Regardless of using docker install on host:
- Rust
- Rust wasip1 target:
```
rustup target add wasm32-wasip1
```
- Rust RISCV target:
```
rustup target add riscv64gc-unknown-linux-gnu
```

## Quick Start

### 1. Compile Your Source to WASM

For Go (included examples):

```bash
# Compile all Go examples to WASM
./examples/scripts/go2wasm.sh

# This creates WASM files in examples/build-wasm/go/
# For example: examples/build-wasm/go/println.wasm
```

### 2. Transpile WASM to C Package

```bash
./docker/wasm2c-package.sh examples/build-wasm/go/println.wasm build/c-packages/println/

# This creates:
#   build/c-packages/println/guest.c      - Generated C code
#   build/c-packages/println/guest.h      - Generated header
#   build/c-packages/println/w2c2_base.h  - w2c2 runtime
```

### 3. Compile to Target Platform

#### AMD64 (Native - for testing)
```bash
./platform/amd64/scripts/c2native-amd64.sh \
    build/c-packages/println \
    build/bin/println.amd64

# Run it
./build/bin/println.amd64
```

#### Zisk

```bash
./platform/zkvm/scripts/c2zkvm.sh \
    build/c-packages/println \
    build/bin/println.zkvm.elf

# Run in zkVM emulator (Need to install this separately)
ziskemu -e build/bin/println.zkvm.elf
```

#### QEMU RISC-V
```bash
./platform/riscv-qemu/scripts/c2riscv-qemu.sh \
    build/c-packages/println \
    build/bin/println.riscv.elf

# Run in QEMU
qemu-system-riscv64 -machine virt -bios none \
    -kernel build/bin/println.riscv.elf -nographic
```

## Examples

All examples below use Go, but the same principles apply to any language that compiles to WASM with WASI support.

### Simple Hello World

```go
// examples/go/println/example.go
package main

import "fmt"

func main() {
    fmt.Println("Hello world from golang")
}
```

### Custom WASM Imports

You can call platform-specific functions from your WASM code using custom imports.

In Go, use `//go:wasmimport`:

```go
// examples/go/with_import/example.go
package main

import "fmt"

//go:wasmimport testmodule testfunc
//go:noescape
func testfunc(a, b uint32) uint32

func main() {
    result := testfunc(1, 2)
    fmt.Printf("testfunc(1, 2) = %d\n", result)
}
```

Implement the import in `platform/*/custom_imports.c`:
```c
// platform/amd64/custom_imports.c
U32 testmodule__testfunc(void* p, U32 a, U32 b) {
    printf("testfunc called with %u, %u\n", a, b);
    return a + b;
}
```

## Memory Limits

For embedded targets with limited memory, use `debug.SetMemoryLimit()`:
```go
import "runtime/debug"

func main() {
    debug.SetMemoryLimit(400 * (1 << 20)) // 400MB limit
    // ...
}
```

# Benchmarks of Rust programs

The benchmark presents the number of instructions executed for a program compiled with various methods:
- "through WASM, -O0" was compiled by `./platform/riscv-qemu-user/scripts/c2riscv-qemu-user.sh` with `-O0` optimization level
- "through WASM, optimized" was compiled by `./platform/riscv-qemu-user/scripts/c2riscv-qemu-user.sh` with non-zero optimization level
- "directly" was compiled with `cargo build --target riscv64gc-unknown-linux-gnu --release`

The number of cycles was measured by using libinsn qemu plugin.


|program|through WASM, -O0| through WASM, optimized|directly|
|---|---|---|---|
|`reva-client-eth`|7,887,190,279|1,419,050,123 (-O1)|388,564,723|
|`fibonacci`|1,033,748|167,179 (-O3)|427,110|
|`hello-world`|42,819|20,634 (-O3)|211,591|

Please note that:
-  `./platform/riscv-qemu-user/scripts/c2riscv-qemu-user.sh` uses target `-march=rv64imad -march=rv64imad` whereas Rust direct compilation uses `rv64gc`.
- the programs could have been compiled for `qemu-system-riscv64` but direct compilation from Rust to baremetal would be more difficult.

These are not expected to affect the benchmark results in a significant way.


## Analysis of the results

Conclusions for `reva-client-eth`:
- the direct build is the fastest
- gcc optimization levels matter a lot
- unoptimized WASM is 20 times slower than the direct build
- `-O1` build is 3.6 times slower than the direct build
- `-O3` build improves on that a little bit - see the "gcc bug"

Conclusions for `fibonacci` and `hello-world`:
- surprisingly optimized WAS build is faster than the direct build

## gcc bug

The optimized `reva-client-eth` build uses the `-O1` optimization level. Using higher optimization leads to non-terminating compilation. It was confirmed that it's a gcc bug. That conclusion was drawn by the following observations:
- clang is able to compile the same sources
- w2c2 was provided with `-f 100` option that results in splitting into many source files; then gcc was stuck at compilation of a single file with ~1000LOC

`reva-client-eth` compiled with `clang` with `-O3` optimization level requires 1.2e9 instructions to execute. That's not much less than when compiled with `gcc` with `-O1` that requires 1.4e9 instructions.

## License

MIT + Apache
