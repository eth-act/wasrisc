#!/bin/bash

set -e

echo "" > go_benchmark_results_aarch64.txt

rustup target add aarch64-unknown-linux-musl
rustup component add rust-std-aarch64-unknown-linux-musl

echo "Translating Go to WASM..."

./examples/scripts/go2wasm.sh

echo "Transpiling WASM to CWASM with wasmtime..."

./docker/docker-shell.sh /root/.wasmtime/bin/wasmtime compile --target aarch64-unknown-linux-musl  examples/build-wasm/go/stateless.wasm -o examples/build-wasm/go/stateless-by-wasmtime/src/stateless.cwasm
(cd examples/build-wasm/go/stateless-by-wasmtime/; RUSTFLAGS='-C target-feature=+crt-static -C link-arg=-static'   cargo build --release --target aarch64-unknown-linux-musl)
./docker/docker-shell.sh qemu-aarch64 -plugin /libinsn.so examples/build-wasm/go/stateless-by-wasmtime/target/aarch64-unknown-linux-musl/release/standalone >> go_benchmark_results_aarch64.txt 2>&1

echo "Transpiling WASM to WASMU with wasmer(cranelift)..."

./docker/docker-shell.sh /root/.wasmer/bin/wasmer compile --cranelift --target aarch64-unknown-linux-musl  examples/build-wasm/go/stateless.wasm -o examples/build-wasm/go/stateless-by-wasmer/src/stateless.wasmu
(cd examples/build-wasm/go/stateless-by-wasmer/; RUSTFLAGS='-C target-feature=+crt-static -C link-arg=-static'   cargo build --release --target aarch64-unknown-linux-musl)
./docker/docker-shell.sh qemu-aarch64 -plugin /libinsn.so examples/build-wasm/go/stateless-by-wasmer/target/aarch64-unknown-linux-musl/release/standalone >> go_benchmark_results_aarch64.txt 2>&1

echo "Transpiling WASM to WASMU with wasmer(llvm)..."

./docker/docker-shell.sh /root/.wasmer/bin/wasmer compile --llvm --target aarch64-unknown-linux-musl  examples/build-wasm/go/stateless.wasm -o examples/build-wasm/go/stateless-by-wasmer/src/stateless.wasmu
(cd examples/build-wasm/go/stateless-by-wasmer/; RUSTFLAGS='-C target-feature=+crt-static -C link-arg=-static'   cargo build --release --target aarch64-unknown-linux-musl)
./docker/docker-shell.sh qemu-aarch64 -plugin /libinsn.so examples/build-wasm/go/stateless-by-wasmer/target/aarch64-unknown-linux-musl/release/standalone >> go_benchmark_results_aarch64.txt 2>&1

echo "Transpiling WASM to WAMR AOT with wamrc..."

./platform/riscv-wamr-qemu-aarch64/scripts/wasm2wamr-qemu-aarch64.sh examples/build-wasm/go/stateless.wasm build/bin/stateless.wamr-aarch64.elf
./docker/docker-shell.sh qemu-aarch64 -plugin /libinsn.so build/bin/stateless.wamr-aarch64.elf >> go_benchmark_results_aarch64.txt 2>&1

echo "Direct compilation..."

(cd examples/go/stateless; GOOS=linux GOARCH=arm64 go build -o ./stateless)
./docker/docker-shell.sh qemu-aarch64 -plugin /libinsn.so examples/go/stateless/stateless >> go_benchmark_results_aarch64.txt 2>&1

echo "Done"

