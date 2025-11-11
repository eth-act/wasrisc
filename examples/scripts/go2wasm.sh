#!/bin/bash
set -e

# Get the examples directory (parent of scripts)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
EXAMPLES_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$EXAMPLES_DIR/build-wasm/go"
GO_EXAMPLES_DIR="$EXAMPLES_DIR/go"

echo "======================================"
echo "Building Go Examples to WASM"
echo "======================================"
echo ""

# Create build directory if it doesn't exist
mkdir -p "$BUILD_DIR"

# Find all directories containing go.mod files
find "$GO_EXAMPLES_DIR" -name "go.mod" -type f | while read -r go_mod; do
    example_dir=$(dirname "$go_mod")
    example_name=$(basename "$example_dir")
    output_wasm="$BUILD_DIR/${example_name}.wasm"

    echo "Building: $example_name"
    echo "  Source: $example_dir"
    echo "  Output: $output_wasm"

    # Build the Go code to WASM
    cd "$example_dir"
    GOOS=wasip1 GOARCH=wasm go build -o "$output_wasm" .
done