#!/bin/bash

set -e

echo "Translating Rust to WASM..."

./examples/scripts/rust2wasm.sh

echo "Translating WASM to C..."

./docker/wasm2c-package.sh examples/build-wasm/rust/fibonacci.wasm build/c-packages/fibonacci/
./docker/wasm2c-package.sh examples/build-wasm/rust/hello_world.wasm build/c-packages/hello_world/
./docker/wasm2c-package.sh examples/build-wasm/rust/reva-client-eth.wasm build/c-packages/reva-client-eth/

echo "Transpiling WASM to CWASM with wasmtime..."

./docker/docker-shell.sh /root/.wasmtime/bin/wasmtime compile --target riscv64gc-unknown-linux-gnu  examples/build-wasm/rust/reva-client-eth.wasm -o examples/build-wasm/rust/reva-client-eth-by-wasmtime/src/reva-client-eth.cwasm

echo "Transpiling WASM to WASMU with wasmer..."

# TODO: Cranelift is used for now because LLVM support is buggy. Once LLVM is fixed in wasmer use `--llvm` flag instead of `cranelift`; https://github.com/wasmerio/wasmer/issues/5951#issuecomment-3632904384
./docker/docker-shell.sh /root/.wasmer/bin/wasmer compile --cranelift --target riscv64gc-unknown-linux-gnu  examples/build-wasm/rust/reva-client-eth.wasm -o examples/build-wasm/rust/reva-client-eth-by-wasmer/src/reva-client-eth.wasmu

echo "Compiling C to RISCV..."

OPT_LEVEL="-O0" ./platform/riscv-qemu-user/scripts/c2riscv-qemu-user.sh build/c-packages/fibonacci/ build/bin/fibonacci.riscv.O0.elf
OPT_LEVEL="-O3" ./platform/riscv-qemu-user/scripts/c2riscv-qemu-user.sh build/c-packages/fibonacci/ build/bin/fibonacci.riscv.O3.elf
(cd examples/rust/fibonacci; cargo build --target riscv64gc-unknown-linux-gnu --release)

OPT_LEVEL="-O0" ./platform/riscv-qemu-user/scripts/c2riscv-qemu-user.sh build/c-packages/hello_world/ build/bin/hello_world.riscv.O0.elf
OPT_LEVEL="-O3" ./platform/riscv-qemu-user/scripts/c2riscv-qemu-user.sh build/c-packages/hello_world/ build/bin/hello_world.riscv.O3.elf
(cd examples/rust/hello_world; cargo build --target riscv64gc-unknown-linux-gnu --release)

OPT_LEVEL="-O0" ./platform/riscv-qemu-user/scripts/c2riscv-qemu-user.sh build/c-packages/reva-client-eth/ build/bin/reva-client-eth.riscv.O0.elf
OPT_LEVEL="-O1" ./platform/riscv-qemu-user/scripts/c2riscv-qemu-user.sh build/c-packages/reva-client-eth/ build/bin/reva-client-eth.riscv.O1.elf
(cd examples/rust/reva-client-eth; cargo build --bin=reva-client-eth --target riscv64gc-unknown-linux-gnu --release)

(cd examples/build-wasm/rust/reva-client-eth-by-wasmtime/; RUSTFLAGS='-C target-feature=+crt-static -C link-arg=-static'   cargo build --release --target riscv64gc-unknown-linux-gnu)
(cd examples/build-wasm/rust/reva-client-eth-by-wasmer/; RUSTFLAGS='-C target-feature=+crt-static -C link-arg=-static'   cargo build --release --target riscv64gc-unknown-linux-gnu)

echo "Executing with qemu-riscv64"

echo "" > rust_benchmark_results.txt

./docker/docker-shell.sh qemu-riscv64 -plugin /libinsn.so build/bin/fibonacci.riscv.O0.elf >> rust_benchmark_results.txt 2>&1
./docker/docker-shell.sh qemu-riscv64 -plugin /libinsn.so build/bin/fibonacci.riscv.O3.elf >> rust_benchmark_results.txt 2>&1
./docker/docker-shell.sh qemu-riscv64 -plugin /libinsn.so examples/rust/fibonacci/target/riscv64gc-unknown-linux-gnu/release/fibonacci >> rust_benchmark_results.txt 2>&1

./docker/docker-shell.sh qemu-riscv64 -plugin /libinsn.so build/bin/hello_world.riscv.O0.elf >> rust_benchmark_results.txt 2>&1
./docker/docker-shell.sh qemu-riscv64 -plugin /libinsn.so build/bin/hello_world.riscv.O3.elf >> rust_benchmark_results.txt 2>&1
./docker/docker-shell.sh qemu-riscv64 -plugin /libinsn.so examples/rust/hello_world/target/riscv64gc-unknown-linux-gnu/release/hello_world >> rust_benchmark_results.txt 2>&1

./docker/docker-shell.sh qemu-riscv64 -plugin /libinsn.so build/bin/reva-client-eth.riscv.O0.elf >> rust_benchmark_results.txt 2>&1
./docker/docker-shell.sh qemu-riscv64 -plugin /libinsn.so build/bin/reva-client-eth.riscv.O1.elf >> rust_benchmark_results.txt 2>&1
./docker/docker-shell.sh qemu-riscv64 -plugin /libinsn.so examples/rust/reva-client-eth/target/riscv64gc-unknown-linux-gnu/release/reva-client-eth >> rust_benchmark_results.txt 2>&1

./docker/docker-shell.sh qemu-riscv64 -plugin /libinsn.so examples/build-wasm/rust/reva-client-eth-by-wasmtime/target/riscv64gc-unknown-linux-gnu/release/standalone >> rust_benchmark_results.txt 2>&1

# `reva-client-eth` via `wasmer` does not work for some reason. The root cause is not yet known. The error is:
# Error: RuntimeError: out of bounds memory access
#    at <unnamed> (<module>[246]:0x3ee0d)
#    at <unnamed> (<module>[138]:0x259a0)
#    at <unnamed> (<module>[247]:0x55244)
#    at <unnamed> (<module>[7]:0x1228)
#./docker/docker-shell.sh qemu-riscv64 -plugin /libinsn.so examples/build-wasm/rust/reva-client-eth-by-wasmer/target/riscv64gc-unknown-linux-gnu/release/standalone >> rust_benchmark_results.txt 2>&1

echo "Done"

