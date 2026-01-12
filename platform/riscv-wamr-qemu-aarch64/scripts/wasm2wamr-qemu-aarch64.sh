#!/bin/bash
set -e

# wasm2riscv-wamr-qemu - Compile WASM to WAMR RISC-V QEMU binary
# Usage: ./platform/riscv-wamr-qemu/scripts/wasm2riscv-wamr-qemu.sh <guest-c-package-dir> <output-elf>

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WAMR_QEMU_DIR="$(dirname "$SCRIPT_DIR")"
DOCKER_DIR="$WAMR_QEMU_DIR/../../docker"
PROJECT_ROOT="$WAMR_QEMU_DIR/../.."
WAMR_ROOT=/opt/wamr-aarch64

# Check arguments
if [ $# -lt 2 ]; then
    echo "Usage: $0 <guest-c-package-dir> <output-elf>"
    echo ""
    echo "Compiles a .wasm file to WAMR-based dynamically linked Linux AARCH64 binary."
    exit 1
fi

INPUT_WASM="$1"
OUTPUT="$2"

# Change to project root
cd "$PROJECT_ROOT"

# Convert to relative paths if needed
if [[ "$INPUT_WASM" == /* ]]; then
    INPUT_WASM=$(realpath --relative-to="$PROJECT_ROOT" "$INPUT_WASM" 2>/dev/null || echo "$INPUT_WASM")
fi
if [[ "$OUTPUT" == /* ]]; then
    OUTPUT=$(realpath --relative-to="$PROJECT_ROOT" "$OUTPUT" 2>/dev/null || echo "$OUTPUT")
fi

# Validate input exists
if [ ! -f "$INPUT_WASM" ]; then
    echo "Error: Input file '$INPUT_WASM' not found"
    exit 1
fi

# Create output directory
mkdir -p "$(dirname "$OUTPUT")"

echo "======================================"
echo "WASM to WAMR Linux AARCH64 Compilation"
echo "======================================"
echo "Guest package: $INPUT_WASM"
echo "Output binary: $OUTPUT"
echo ""

# !!! --bounds-checks=0 works with dynamically linked musl !!!
#
"$DOCKER_DIR/docker-shell.sh" \
    wamrc --target=aarch64 \
    --opt-level=3 \
    --bounds-checks=0 \
    -o $OUTPUT.aarch64.wamr $1

gcc platform/riscv-wamr-qemu/file2c/file2c.c \
    -o platform/riscv-wamr-qemu/file2c/file2c

# The byte buffer can be WASM binary data when
# interpreter or JIT is enabled, or AOT binary
# data when AOT is enabled.
#
# https://github.com/bytecodealliance/wasm-micro-runtime/blob/main/core/iwasm/include/wasm_export.h
platform/riscv-wamr-qemu/file2c/file2c \
    $OUTPUT.aarch64.wamr \
    wasmModuleBuffer > $OUTPUT.aarch64.wamr.c

# Compile everything in one command via Docker
echo "Compiling..."

# RISC-V toolchain prefix
PREFIX=aarch64-linux-musl-

# Compiler flags (using -O0 for faster compilation of large generated files)
CFLAGS=(
    -D__bool_true_false_are_defined
    -ffunction-sections
    -fdata-sections
    -O3
    -g
    -Wall
)

# Include directories
INCLUDES=(
    -I"$WAMR_ROOT/core/iwasm/include"
    -I"$WAMR_ROOT/core/shared/utils"
    -I"$WAMR_ROOT/core/shared/utils/uncommon"
    -I"$WAMR_ROOT/core/shared/platform/zkvm"
)

# Source files
SOURCES=(
    platform/riscv-wamr-qemu-aarch64/main.c
    "$OUTPUT.aarch64.wamr.c"
)

# Linker flags (matching demo-qemu-virt-riscv/Makefile)
LDFLAGS=(
    -L"$WAMR_ROOT"
    -liwasm
    -Wl,--gc-sections
    -Wl,-Map="${OUTPUT%.elf}.map"
)

# Link libraries
LIBS=(-lc -lm -lgcc)

"$DOCKER_DIR/docker-shell.sh" ${PREFIX}gcc \
    "${CFLAGS[@]}" \
    "${INCLUDES[@]}" \
    "${SOURCES[@]}" \
    "${LDFLAGS[@]}" \
    "${LIBS[@]}" \
    -o "$OUTPUT" 2>&1

# Check if compilation succeeded
if [ $? -eq 0 ] && [ -f "$OUTPUT" ]; then
    SIZE=$(du -h "$OUTPUT" | cut -f1)
    echo "Compiled successfully"
    echo ""
    echo "======================================"
    echo "Binary created successfully!"
    echo "======================================"
    echo ""
    echo "Location: $OUTPUT"
    echo "Size: $SIZE"
    echo ""
    echo "To run in QEMU:"
    echo "  ./docker/docker-shell.sh qemu-aarch64 -plugin /libinsn.so <output-elf>"
    echo ""
else
    echo "Error: Compilation failed"
    exit 1
fi

