#!/bin/bash

set -e

echo "Translating Go to WASM..."

./examples/scripts/go2wasm.sh

echo "Translating WASM to C..."

./platform/wasm2c-package.sh examples/build-wasm/go/stateless.wasm build/c-packages/stateless

echo "Transpiling WASM to CWASM with wasmtime..."

/root/.wasmtime/bin/wasmtime compile --target riscv64gc-unknown-linux-gnu  examples/build-wasm/go/stateless.wasm -o examples/build-wasm/go/stateless-by-wasmtime/src/stateless.cwasm

echo "Transpiling WASM to WASMU with wasmer..."

# TODO: Cranelift is used for now because LLVM support is buggy. Once LLVM is fixed in wasmer use `--llvm` flag instead of `cranelift`; https://github.com/wasmerio/wasmer/issues/5951#issuecomment-3632904384
/root/.wasmer/bin/wasmer compile --cranelift --target riscv64gc-unknown-linux-gnu  examples/build-wasm/go/stateless.wasm -o examples/build-wasm/go/stateless-by-wasmer/src/stateless.wasmu

echo "Transpiling WASM to WAMR AOT with wamrc..."

./platform/riscv-wamr-qemu/scripts/wasm2wamr-qemu.sh examples/build-wasm/go/stateless.wasm build/bin/stateless.wamr.elf

echo "Compiling C to RISCV..."

OPT_LEVEL="-O0" ./platform/riscv-qemu/scripts/c2riscv-qemu.sh build/c-packages/stateless/ build/bin/stateless.riscv.O0.elf
ls -l build/bin/
# On the CI runner this seems to trigger an OOM error:
# clang: error: unable to execute command: Killed
#OPT_LEVEL="-O3" ./platform/riscv-qemu/scripts/c2riscv-qemu.sh build/c-packages/stateless/ build/bin/stateless.riscv.O3.elf
(cd examples/go/stateless; GOOS=linux GOARCH=riscv64 go build -buildvcs=false -o ./stateless)
(cd examples/build-wasm/go/stateless-by-wasmtime/; RUSTFLAGS='-C target-feature=+crt-static -C link-arg=-static'   cargo build --release --target riscv64gc-unknown-linux-gnu)
(cd examples/build-wasm/go/stateless-by-wasmer/; RUSTFLAGS='-C target-feature=+crt-static -C link-arg=-static'   cargo build --release --target riscv64gc-unknown-linux-gnu)

echo "Executing with qemu-riscv64"

#qemu-riscv64 -plugin /libinsn.so build/bin/stateless.riscv.O3.elf >> go_benchmark_results.txt 2>&1

. ./benchmark_utils.sh

success_string="ExecuteStateless succeeded!"

run_qemu "$success_string" "false" "native"         "examples/go/stateless/stateless"
run_qemu "$success_string" "true" "w2c2-O0"         "build/bin/stateless.riscv.O0.elf"
#run_qemu "$success_string" "true" "w2c2-O3"         "build/bin/stateless.riscv.O3.elf"
run_qemu "$success_string" "false" "wasmtime"       "examples/build-wasm/go/stateless-by-wasmtime/target/riscv64gc-unknown-linux-gnu/release/standalone"
run_qemu "$success_string" "false" "wasmer"         "examples/build-wasm/go/stateless-by-wasmer/target/riscv64gc-unknown-linux-gnu/release/standalone"
run_qemu "$success_string" "true"  "wamr"           "build/bin/stateless.wamr.elf"

results_to_json > stateless.json

echo "Done"

