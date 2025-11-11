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

### Docker (Recommended)
The easiest way to build is using the provided Docker environment, which includes:
- RISC-V GNU Toolchain with newlib (rv64ima)
- w2c2 WebAssembly-to-C transpiler
- All dependencies pre-configured

> Running the docker script the first time, will take some time because it is rebuilding the RISCV gnu toolchain from source.

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

## License

MIT + Apache
