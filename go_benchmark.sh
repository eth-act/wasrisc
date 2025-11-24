#!/bin/bash

set -e

echo "Translating Go to WASM..."

./examples/scripts/go2wasm.sh

echo "Translating WASM to C..."

./docker/wasm2c-package.sh examples/build-wasm/go/stateless.wasm build/c-packages/stateless

echo "Compiling C to RISCV..."

OPT_LEVEL="-O0" ./platform/riscv-qemu-user/scripts/c2riscv-qemu-user.sh build/c-packages/stateless/ build/bin/stateless.riscv.O0.elf
OPT_LEVEL="-O3" ./platform/riscv-qemu-user/scripts/c2riscv-qemu-user.sh build/c-packages/stateless/ build/bin/stateless.riscv.O3.elf
(cd examples/go/stateless; GOOS=linux GOARCH=riscv64 go build -o ./stateless)

echo "Executing with qemu-riscv64"

echo "" > go_benchmark_results.txt

./docker/docker-shell.sh qemu-riscv64 -plugin /libinsn.so build/bin/stateless.riscv.O0.elf >> go_benchmark_results.txt 2>&1
./docker/docker-shell.sh qemu-riscv64 -plugin /libinsn.so build/bin/stateless.riscv.O3.elf >> go_benchmark_results.txt 2>&1
./docker/docker-shell.sh qemu-riscv64 -plugin /libinsn.so examples/go/stateless/stateless >> go_benchmark_results.txt 2>&1

echo "Done"

