# skunkworks-go-wasm

## Prerequisites

* Rust toolchain (for building emulator)
* Make
* GNU toolchain for RISC-V in `/opt/riscv-newlib`
* w2c2 in `/opt/w2c2/w2c2`

### GNU toolchain for RISC-V

```
git clone https://github.com/riscv/riscv-gnu-toolchain
cd riscv-gnu-toolchain
sudo apt-get install autoconf automake autotools-dev curl python3 python3-pip python3-tomli libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev ninja-build git cmake libglib2.0-dev libslirp-dev
./configure --prefix=/opt/riscv-newlib --with-arch=rv64ima --disable-gdb --with-cmodel=medany
sudo make -j 8
```

#### Troubleshooting

If `make` fails to recursively clone needed submodules, try `git clone --recursive https://github.com/riscv/riscv-gnu-toolchain` instead. This takes significantly longer though

### w2c2

```
cd /opt
git clone https://github.com/turbolent/w2c2.git
```

## Building

### Build and run Everything


```
make all
```

#### With custom input file

```
cd platform
make -C zkvm example.zkvm.bin
ziskemu -e ./zkvm/example.zkvm.bin -i go.png
```

#### Debugging

It's possible to compile to amd64 and e.g. run with gdb:

```
make compile-amd64
./amd64/example.amd64.bin
```

## Memory

`wasmMemoryAllocate` allocates by default a max of 1<<12=4096 pages (min 51 possible)
with each page having 65536 (1<<16) bytes.

Multiplied that's in total 250 MB.

The memory-mapped I/O regions for the target are (TODO):

- **Input Buffer** at `0x90000000` - Where input data is placed for the program
- **System Address** at `0xa0000000` (= `RAM_ADDR` = `REG_FIRST`) - Contains system address
- **UART Address** at `SYS_ADDR + 512` - Single bytes written here will be copied to the standard output
- **Output Buffer** at `0xa0010000` - Where programs write output data
- **RAM** starting at `0xa0020000` - Main memory for program execution (~512MB)

- **Initialization Stack** starting after BSS section (1 MB)

zisk/core/src/mem.rs

## Maintainability of Components

### Golang 1.x

Golang 1.x APIs are guaranteed to be stable. This doesn't extend to the ABI though.

https://go.dev/doc/go1compat

### Wasm platform

Wasm develops rapidly with the 3.0 standard being completed in September 2025. dotnet 9 und 10
emit code for Wasm 2.0 while most tooling like runtimes and utilities still only support Wasm 1.0.

While this is bad for maintenance, this might even out since it's an open standard with a large
and active community.

But generally it might make sense to limit dependencies.

#### Official tools

https://github.com/bytecodealliance/wasm-tools

https://github.com/WebAssembly/wabt

### Golang wasip1 port

Golang ports are not guaranteed to be maintained upstream indefinitely. Since the platform quickly grows it's wasm support is unlikely to be removed. However it may be necessary to adapt to current wasip2 and wasm modules for instance.

https://go.dev/blog/wasi#the-future-of-wasm-in-go

### w2c2

w2c2 is in active development and usage. Also there are blog articles about it and various forks.

While supporting WASM and WASI, WASM 2.0/wasip2 modules are extracted in a separate build step.

https://github.com/turbolent/w2c2


## Current Limitations

### only ~256 MB of memory addressed

### Concurrency

goroutines are in principle available even without parallelism. However it's necessary to take into account scheduling.

#### Yielding goroutines

While not an ideal pattern in Go programs on any platform, for instance a tight loop

```
for {}
```

may never yield execution to other goroutines. Even doing I/O through UART in general doesn't solve this, only explicitly running `runtime.Gosched()`.

#### Timing

The VM has no clock but...

### tbd
