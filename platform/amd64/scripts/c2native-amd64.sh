#!/bin/bash
set -e

# c2native-amd64.sh - Compile guest C package to native AMD64 binary
# Usage: ./platform/amd64/scripts/c2native-amd64.sh <guest-package-dir> <output-binary>

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AMD64_DIR="$(dirname "$SCRIPT_DIR")"
DOCKER_DIR="$AMD64_DIR/../../docker"
PROJECT_ROOT="$AMD64_DIR/../.."

# Check arguments
if [ $# -lt 2 ]; then
    echo "Usage: $0 <guest-package-dir> <output-binary>"
    echo ""
    echo "Compiles a guest C package to native AMD64 binary for testing/debugging."
    echo ""
    echo "Example:"
    echo "  $0 build/c-packages/basic/ build/bin/basic.amd64.bin"
    echo ""
    echo "Requirements:"
    echo "  - guest.c (generated WASM-to-C code)"
    echo "  - guest.h (generated header)"
    echo "  - w2c2_base.h (w2c2 runtime header)"
    exit 1
fi

GUEST_DIR="$1"
OUTPUT="$2"

# Change to project root
cd "$PROJECT_ROOT"

# Convert absolute paths to relative (if inside project)
if [[ "$GUEST_DIR" == /* ]]; then
    GUEST_DIR=$(realpath --relative-to="$PROJECT_ROOT" "$GUEST_DIR" 2>/dev/null || echo "$GUEST_DIR")
fi
if [[ "$OUTPUT" == /* ]]; then
    OUTPUT=$(realpath --relative-to="$PROJECT_ROOT" "$OUTPUT" 2>/dev/null || echo "$OUTPUT")
fi

# Validate guest package
if [ ! -f "$GUEST_DIR/guest.c" ]; then
    echo "Error: guest.c not found in $GUEST_DIR"
    echo "Make sure you've run wasm2c-package.sh first to create the C package."
    exit 1
fi

if [ ! -f "$GUEST_DIR/guest.h" ]; then
    echo "Error: guest.h not found in $GUEST_DIR"
    exit 1
fi

if [ ! -f "$GUEST_DIR/w2c2_base.h" ]; then
    echo "Error: w2c2_base.h not found in $GUEST_DIR"
    exit 1
fi

# Create output directory if needed
OUTPUT_DIR=$(dirname "$OUTPUT")
mkdir -p "$OUTPUT_DIR"

echo "======================================"
echo "C to Native AMD64 Compilation"
echo "======================================"
echo "Guest package: $GUEST_DIR"
echo "Output binary: $OUTPUT"
echo ""

# Compile everything in one command via Docker
echo "Compiling..."

# Compiler flags
# Note: Using embedded WASI for both native and embedded targets because:
# - w2c2's upstream native WASI is missing implementations for some functions Go needs
# - Specifically, poll_oneoff returns WASI_ERRNO_NOSYS which causes Go to panic
# - The embedded WASI has minimal working stubs that return success for these functions
CFLAGS=(
    -g
    -DAMD64
    -O0
    -flto
)

# Include directories
INCLUDES=(
    -I"$GUEST_DIR"
    -Iwasi/embedded
    -Iplatform/amd64
)

# Source files
SOURCES=(
    platform/amd64/main.c
    platform/amd64/amd64.c
    platform/amd64/custom_imports.c
    $(find $GUEST_DIR -type f -name "*.c")
    wasi/embedded/wasi.c
)

# Link libraries
LIBS=(-lm)

"$DOCKER_DIR/docker-shell.sh" gcc \
    "${CFLAGS[@]}" \
    "${INCLUDES[@]}" \
    "${SOURCES[@]}" \
    "${LIBS[@]}" \
    -o "$OUTPUT"

# Check if compilation succeeded
if [ ! -f "$OUTPUT" ]; then
    echo "Error: Compilation failed"
    exit 1
fi

echo "Compiled successfully"
echo ""
echo "======================================"
echo "Binary created successfully!"
echo "======================================"
echo ""
echo "Location: $OUTPUT"
echo "Size: $(du -h "$OUTPUT" | cut -f1)"
echo ""
echo "To run(on AMD64):"
echo "  ./$OUTPUT"
echo "  ./$OUTPUT -i input-file.png"
echo ""
