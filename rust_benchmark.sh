#!/bin/bash

set -e

echo "Translating Rust to WASM..."

./examples/scripts/rust2wasm.sh

echo "Translating WASM to C..."

./platform/wasm2c-package.sh examples/build-wasm/rust/reva-client-eth.wasm build/c-packages/reva-client-eth/

echo "Transpiling WASM to CWASM with wasmtime..."

/root/.wasmtime/bin/wasmtime compile --target riscv64gc-unknown-linux-gnu  examples/build-wasm/rust/reva-client-eth.wasm -o examples/build-wasm/rust/reva-client-eth-by-wasmtime/src/reva-client-eth.cwasm

echo "Transpiling WASM to WASMU with wasmer..."

# TODO: Cranelift is used for now because LLVM support is buggy. Once LLVM is fixed in wasmer use `--llvm` flag instead of `cranelift`; https://github.com/wasmerio/wasmer/issues/5951#issuecomment-3632904384
/root/.wasmer/bin/wasmer compile --cranelift --target riscv64gc-unknown-linux-gnu  examples/build-wasm/rust/reva-client-eth.wasm -o examples/build-wasm/rust/reva-client-eth-by-wasmer/src/reva-client-eth.wasmu

echo "Transpiling WASM to WAMR AOT with wamrc..."

./platform/riscv-wamr-qemu/scripts/wasm2wamr-qemu.sh examples/build-wasm/rust/reva-client-eth.wasm build/bin/reva-client-eth.wamr.elf

echo "Compiling C to RISCV..."

OPT_LEVEL="-O0" ./platform/riscv-qemu/scripts/c2riscv-qemu.sh build/c-packages/reva-client-eth/ build/bin/reva-client-eth.riscv.O0.elf
OPT_LEVEL="-O3" ./platform/riscv-qemu/scripts/c2riscv-qemu.sh build/c-packages/reva-client-eth/ build/bin/reva-client-eth.riscv.O3.elf
(cd examples/rust/reva-client-eth; RUSTFLAGS='-C target-feature=+crt-static -C link-arg=-static' cargo build --bin=reva-client-eth --target riscv64gc-unknown-linux-gnu --release)

(cd examples/build-wasm/rust/reva-client-eth-by-wasmtime/; RUSTFLAGS='-C target-feature=+crt-static -C link-arg=-static'   cargo build --release --target riscv64gc-unknown-linux-gnu)
(cd examples/build-wasm/rust/reva-client-eth-by-wasmer/; RUSTFLAGS='-C target-feature=+crt-static -C link-arg=-static'   cargo build --release --target riscv64gc-unknown-linux-gnu)

echo "Executing with qemu-riscv64"

. ./benchmark_utils.sh

success_string="0xc2558f8143d5f5acb8382b8cb2b8e2f1a10c8bdfeededad850eaca048ed85d8f"

run_qemu "$success_string" "false" "native"         "examples/rust/reva-client-eth/target/riscv64gc-unknown-linux-gnu/release/reva-client-eth"
run_qemu "$success_string" "true"  "w2c2-O0"        "build/bin/reva-client-eth.riscv.O0.elf"
run_qemu "$success_string" "true"  "w2c2-O3"        "build/bin/reva-client-eth.riscv.O3.elf"
run_qemu "$success_string" "false" "wasmtime"       "examples/build-wasm/rust/reva-client-eth-by-wasmtime/target/riscv64gc-unknown-linux-gnu/release/standalone"
run_qemu "$success_string" "true"  "wamr"           "build/bin/reva-client-eth.wamr.elf"

# `reva-client-eth` via `wasmer` does not work for some reason. The root cause is not yet known. The error is:
# Error: RuntimeError: out of bounds memory access
#    at <unnamed> (<module>[246]:0x3ee0d)
#    at <unnamed> (<module>[138]:0x259a0)
#    at <unnamed> (<module>[247]:0x55244)
#    at <unnamed> (<module>[7]:0x1228)
# qemu-riscv64 -plugin /libinsn.so examples/build-wasm/rust/reva-client-eth-by-wasmer/target/riscv64gc-unknown-linux-gnu/release/standalone >> rust_benchmark_results.txt 2>&1

results_to_json > reva-client-eth.json

echo "Done"

