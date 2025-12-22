#!/bin/bash

set -e

echo "Translating Go to WASM..."

./examples/scripts/go2wasm.sh

echo "Translating WASM to C..."

./docker/wasm2c-package.sh examples/build-wasm/go/stateless.wasm build/c-packages/stateless

echo "Transpiling WASM to CWASM with wasmtime..."

./docker/docker-shell.sh /root/.wasmtime/bin/wasmtime compile --target riscv64gc-unknown-linux-gnu  examples/build-wasm/go/stateless.wasm -o examples/build-wasm/go/stateless-by-wasmtime/src/stateless.cwasm

echo "Transpiling WASM to WASMU with wasmer..."

# TODO: Cranelift is used for now because LLVM support is buggy. Once LLVM is fixed in wasmer use `--llvm` flag instead of `cranelift`; https://github.com/wasmerio/wasmer/issues/5951#issuecomment-3632904384
./docker/docker-shell.sh /root/.wasmer/bin/wasmer compile --cranelift --target riscv64gc-unknown-linux-gnu  examples/build-wasm/go/stateless.wasm -o examples/build-wasm/go/stateless-by-wasmer/src/stateless.wasmu

echo "Transpiling WASM to WAMR AOT with wamrc..."

./platform/riscv-wamr-qemu/scripts/wasm2wamr-qemu.sh examples/build-wasm/go/stateless.wasm build/bin/stateless.wamr.elf

echo "Compiling C to RISCV..."

OPT_LEVEL="-O0" ./platform/riscv-qemu-user/scripts/c2riscv-qemu-user.sh build/c-packages/stateless/ build/bin/stateless.riscv.O0.elf
OPT_LEVEL="-O3 -fno-reorder-blocks" ./platform/riscv-qemu-user/scripts/c2riscv-qemu-user.sh build/c-packages/stateless/ build/bin/stateless.riscv.O3.elf
(cd examples/go/stateless; GOOS=linux GOARCH=riscv64 go build -o ./stateless)
(cd examples/build-wasm/go/stateless-by-wasmtime/; RUSTFLAGS='-C target-feature=+crt-static -C link-arg=-static'   cargo build --release --target riscv64gc-unknown-linux-gnu)
(cd examples/build-wasm/go/stateless-by-wasmer/; RUSTFLAGS='-C target-feature=+crt-static -C link-arg=-static'   cargo build --release --target riscv64gc-unknown-linux-gnu)

echo "Executing with qemu-riscv64"

echo "" > go_benchmark_results.txt

./docker/docker-shell.sh qemu-riscv64 -plugin /libinsn.so build/bin/stateless.riscv.O0.elf >> go_benchmark_results.txt 2>&1
./docker/docker-shell.sh qemu-riscv64 -plugin /libinsn.so build/bin/stateless.riscv.O3.elf >> go_benchmark_results.txt 2>&1
./docker/docker-shell.sh qemu-riscv64 -plugin /libinsn.so examples/go/stateless/stateless >> go_benchmark_results.txt 2>&1
./docker/docker-shell.sh qemu-riscv64 -plugin /libinsn.so examples/build-wasm/go/stateless-by-wasmtime/target/riscv64gc-unknown-linux-gnu/release/standalone >> go_benchmark_results.txt 2>&1
./docker/docker-shell.sh qemu-riscv64 -plugin /libinsn.so examples/build-wasm/go/stateless-by-wasmer/target/riscv64gc-unknown-linux-gnu/release/standalone >> go_benchmark_results.txt 2>&1
./docker/docker-shell.sh qemu-system-riscv64 -d plugin -machine virt -m 1024M -plugin /libinsn.so -kernel build/bin/stateless.wamr.elf -nographic >> go_benchmark_results.txt 2>&1

echo "Done"

