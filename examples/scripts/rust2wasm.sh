#!/bin/bash
set -e

# Get the examples directory (parent of scripts)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
EXAMPLES_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$EXAMPLES_DIR/build-wasm/rust"
GO_EXAMPLES_DIR="$EXAMPLES_DIR/rust"

echo "======================================"
echo "Building Rust Examples to WASM"
echo "======================================"
echo ""

# Create build directory if it doesn't exist
mkdir -p "$BUILD_DIR"

# Find all directories containing go.mod files
find "$GO_EXAMPLES_DIR" -maxdepth 2 -name "Cargo.toml" -type f | while read -r cargo_toml; do
    example_dir=$(dirname "$cargo_toml")
    example_name=$(basename "$example_dir")
    output_wasm="$BUILD_DIR/${example_name}.wasm"

    echo "Building: $example_name"
    echo "  Source: $example_dir"
    echo "  Output: $output_wasm"

    # Build the Go code to WASM
    cd "$example_dir"
    cargo build --target wasm32-wasip1 --bin $example_name --release
    cp "target/wasm32-wasip1/release/$example_name.wasm" "$output_wasm"
done
