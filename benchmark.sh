#!/bin/bash

set -e

echo "Translating Rust to WASM..."

./examples/scripts/rust2wasm.sh

echo "Translating WASM to C..."

./docker/wasm2c-package.sh examples/build-wasm/rust/fibonacci.wasm build/c-packages/fibonacci/
./docker/wasm2c-package.sh examples/build-wasm/rust/hello_world.wasm build/c-packages/hello_world/
./docker/wasm2c-package.sh examples/build-wasm/rust/reva-client-eth.wasm build/c-packages/reva-client-eth/

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

echo "Executing with qemu-riscv64"

echo "" > benchmark_results.txt

./docker/docker-shell.sh qemu-riscv64 -plugin /libinsn.so build/bin/fibonacci.riscv.O0.elf >> benchmark_results.txt 2>&1
./docker/docker-shell.sh qemu-riscv64 -plugin /libinsn.so build/bin/fibonacci.riscv.O3.elf >> benchmark_results.txt 2>&1
./docker/docker-shell.sh qemu-riscv64 -plugin /libinsn.so examples/rust/fibonacci/target/riscv64gc-unknown-linux-gnu/release/fibonacci >> benchmark_results.txt 2>&1

./docker/docker-shell.sh qemu-riscv64 -plugin /libinsn.so build/bin/hello_world.riscv.O0.elf >> benchmark_results.txt 2>&1
./docker/docker-shell.sh qemu-riscv64 -plugin /libinsn.so build/bin/hello_world.riscv.O3.elf >> benchmark_results.txt 2>&1
./docker/docker-shell.sh qemu-riscv64 -plugin /libinsn.so examples/rust/hello_world/target/riscv64gc-unknown-linux-gnu/release/hello_world >> benchmark_results.txt 2>&1

./docker/docker-shell.sh qemu-riscv64 -plugin /libinsn.so build/bin/reva-client-eth.riscv.O0.elf >> benchmark_results.txt 2>&1
./docker/docker-shell.sh qemu-riscv64 -plugin /libinsn.so build/bin/reva-client-eth.riscv.O1.elf >> benchmark_results.txt 2>&1
./docker/docker-shell.sh qemu-riscv64 -plugin /libinsn.so examples/rust/reva-client-eth/target/riscv64gc-unknown-linux-gnu/release/reva-client-eth >> benchmark_results.txt 2>&1

echo "Done"

