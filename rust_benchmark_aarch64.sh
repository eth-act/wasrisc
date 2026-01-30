#!/bin/bash

set -e

echo "" > rust_benchmark_results_aarch64.txt

echo "Translating Rust to WASM..."

./examples/scripts/rust2wasm.sh

echo "Transpiling WASM to CWASM with wasmtime..."

/root/.wasmtime/bin/wasmtime compile --target aarch64-unknown-linux-musl  examples/build-wasm/go/stateless.wasm -o examples/build-wasm/go/stateless-by-wasmtime/src/stateless.cwasm
(cd examples/build-wasm/go/stateless-by-wasmtime/; RUSTFLAGS='-C target-feature=+crt-static -C link-arg=-static'   cargo build --release --target aarch64-unknown-linux-musl)
qemu-aarch64 -plugin /libinsn.so examples/build-wasm/go/stateless-by-wasmtime/target/aarch64-unknown-linux-musl/release/standalone >> rust_benchmark_results_aarch64.txt 2>&1

echo "Transpiling WASM to WASMU with wasmer(cranelift)..."

/root/.wasmer/bin/wasmer compile --cranelift --target aarch64-unknown-linux-musl  examples/build-wasm/go/stateless.wasm -o examples/build-wasm/go/stateless-by-wasmer/src/stateless.wasmu
(cd examples/build-wasm/go/stateless-by-wasmer/; RUSTFLAGS='-C target-feature=+crt-static -C link-arg=-static'   cargo build --release --target aarch64-unknown-linux-musl)
qemu-aarch64 -plugin /libinsn.so examples/build-wasm/go/stateless-by-wasmer/target/aarch64-unknown-linux-musl/release/standalone >> rust_benchmark_results_aarch64.txt 2>&1

echo "Transpiling WASM to WASMU with wasmer(llvm)..."

/root/.wasmer/bin/wasmer compile --llvm --target aarch64-unknown-linux-musl  examples/build-wasm/go/stateless.wasm -o examples/build-wasm/go/stateless-by-wasmer/src/stateless.wasmu
(cd examples/build-wasm/go/stateless-by-wasmer/; RUSTFLAGS='-C target-feature=+crt-static -C link-arg=-static'   cargo build --release --target aarch64-unknown-linux-musl)
 qemu-aarch64 -plugin /libinsn.so examples/build-wasm/go/stateless-by-wasmer/target/aarch64-unknown-linux-musl/release/standalone >> rust_benchmark_results_aarch64.txt 2>&1

echo "Transpiling WASM to WAMR AOT with wamrc..."

./platform/riscv-wamr-qemu-aarch64/scripts/wasm2wamr-qemu-aarch64.sh examples/build-wasm/go/stateless.wasm build/bin/stateless.wamr-aarch64.elf
qemu-aarch64 -plugin /libinsn.so build/bin/stateless.wamr-aarch64.elf >> rust_benchmark_results_aarch64.txt 2>&1

echo "Direct compilation..."

(cd examples/go/stateless; GOOS=linux GOARCH=arm64 go build -o ./stateless)
qemu-aarch64 -plugin /libinsn.so examples/go/stateless/stateless >> rust_benchmark_results_aarch64.txt 2>&1

echo "Done"

