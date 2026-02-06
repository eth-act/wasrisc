#!/bin/bash

set -eu -o pipefail

# wasm2c-package.sh - Package WASM to C with all dependencies
# Usage: ./docker/wasm2c-package.sh input.wasm output-dir/

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."

# Check arguments
if [ $# -lt 2 ]; then
    echo "Usage: $0 <input.wasm> <output-dir>"
    echo ""
    echo "Paths should be relative to project root or absolute."
    echo ""
    echo "Example:"
    echo "  $0 examples/build-wasm/go/basic.wasm build/c-packages/basic/"
    echo ""
    echo "Creates a self-contained C package with:"
    echo "  - guest.c (generated C code)"
    echo "  - guest.h (generated header)"
    echo "  - w2c2_base.h (w2c2 runtime header)"
    exit 1
fi

INPUT_WASM="$1"
OUTPUT_DIR="$2"

# Change to project root
cd "$PROJECT_ROOT"

# Convert absolute paths to relative (if inside project)
if [[ "$INPUT_WASM" == /* ]]; then
    INPUT_WASM=$(realpath --relative-to="$PROJECT_ROOT" "$INPUT_WASM" 2>/dev/null || echo "$INPUT_WASM")
fi
if [[ "$OUTPUT_DIR" == /* ]]; then
    OUTPUT_DIR=$(realpath --relative-to="$PROJECT_ROOT" "$OUTPUT_DIR" 2>/dev/null || echo "$OUTPUT_DIR")
fi

# Validate input exists
if [ ! -f "$INPUT_WASM" ]; then
    echo "Error: Input file '$INPUT_WASM' not found"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo "======================================"
echo "WASM to C Packaging"
echo "======================================"
echo "Input:  $INPUT_WASM"
echo "Output: $OUTPUT_DIR"
echo ""

# Copy WASM file to temporary guest.wasm (so w2c2 generates consistent "guest" names)
# Note: The filename is used in numerous places in the generated C. We manually change
# the name to be guest.wasm so we don't need to template the C code.
echo "Preparing WASM file..."
TEMP_GUEST_WASM="$OUTPUT_DIR/guest.wasm"
cp "$INPUT_WASM" "$TEMP_GUEST_WASM"

# Run w2c2 via Docker to generate C files with "guest" module name
#
# Also apply source file splitting which accelerates compilation even in a single threaded build.

# Remove s0*.c files from previous builds
rm -f $OUTPUT_DIR/s00000*.c

echo "Transpiling WASM to C..."
"$PROJECT_ROOT/docker-shell.sh" w2c2 -f 256 -p "$TEMP_GUEST_WASM" "$OUTPUT_DIR/guest.c"

# Remove temporary guest.wasm
rm -f "$TEMP_GUEST_WASM"

# Check if transpilation succeeded
if [ ! -f "$OUTPUT_DIR/guest.c" ]; then
    echo "Error: Transpilation failed, guest.c not created"
    exit 1
fi


# Copy w2c2_base.h from Docker container
echo ""
echo "Extracting w2c2 runtime header..."
cp /opt/w2c2/w2c2/w2c2_base.h "$OUTPUT_DIR/w2c2_base.h"

if [ ! -f "$OUTPUT_DIR/w2c2_base.h" ]; then
    echo "Error: Failed to copy w2c2_base.h"
    exit 1
fi
