#!/bin/bash
set -eu -o pipefail

# Get the examples directory (parent of scripts)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")/.."
EXAMPLES_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$EXAMPLES_DIR/build-wasm/dotnet"
DOTNET_EXAMPLES_DIR="$EXAMPLES_DIR/dotnet"

echo "======================================"
echo "Building dotnet Examples to WASM"
echo "======================================"
echo ""

# Create build directory if it doesn't exist
mkdir -p "$BUILD_DIR"

# Find all directories containing .csproj files
find "$DOTNET_EXAMPLES_DIR" -maxdepth 2 -name '*.csproj' -type f | while read -r csproj; do
    example_dir=$(dirname "$csproj")
    example_name=$(basename "$example_dir")
    output_wasm="$BUILD_DIR/${example_name}.wasm"

    echo "Building: $example_name"
    echo "  Source: $example_dir"
    echo "  Output: $output_wasm"

    # Build the dotnet code to wasip2 WASM
    cd "$example_dir"
    dotnet publish -r wasi-wasm
    rm -rf $BUILD_DIR/bin
    rm -rf $BUILD_DIR/obj
    mv $example_dir/bin $BUILD_DIR/bin
    mv $example_dir/obj $BUILD_DIR/obj

    # Extract wasip1 from wasip2 WASM
    cd "$PROJECT_ROOT"
    wasm-tools component unbundle --module-dir $BUILD_DIR/mod --output $BUILD_DIR/mod/guest.wasm $BUILD_DIR/bin/Release/net10.0/wasi-wasm/publish/Example.wasm
    wasm2wat $BUILD_DIR/mod/unbundled-module0.wasm > $BUILD_DIR/mod/unbundled-module0.wat
    go run $PROJECT_ROOT/examples/scripts/dotnet2wasm/dotnet2wasm.go -in $BUILD_DIR/mod/unbundled-module0.wat -out $BUILD_DIR/mod/unbundled-module0-patched.wat
    wat2wasm $BUILD_DIR/mod/unbundled-module0-patched.wat -o $output_wasm
done
