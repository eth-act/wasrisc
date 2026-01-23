#!/bin/bash
set -e

# c2riscv-qemu-user.sh - Compile C package to RISC-V QEMU virt binary
# Usage: ./platform/riscv-qemu/scripts/c2riscv-qemu-user.sh <guest-c-package-dir> <output-elf>

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RISCV_QEMU_DIR="$(dirname "$SCRIPT_DIR")"
DOCKER_DIR="$RISCV_QEMU_DIR/../../docker"
PROJECT_ROOT="$RISCV_QEMU_DIR/../.."

# Check arguments
if [ $# -lt 2 ]; then
    echo "Usage: $0 <guest-c-package-dir> <output-elf>"
    echo ""
    echo "Compiles a C package (from w2c2) to RISC-V binary for QEMU virt machine."
    echo ""
    echo "Arguments:"
    echo "  guest-c-package-dir  Directory containing guest.c, guest.h, w2c2_base.h"
    echo "  output-elf           Output RISC-V Linux ELF binary path"
    echo ""
    echo "Example:"
    echo "  $0 build/.c-packages/println build/bin/println.riscv.elf"
    echo ""
    echo "To run in QEMU:"
    echo "  qemu-riscv64  build/bin/println.riscv.elf"
    echo ""
    exit 1
fi

GUEST_DIR="$1"
OUTPUT="$2"

if [ -n "$OPT_LEVEL" ]; then
    OPT_LEVEL="$OPT_LEVEL"
    echo "Using provided OPT_LEVEL: $OPT_LEVEL"
else
    # OPT_LEVEL is not set, set default value
    OPT_LEVEL="-O0"
    echo "OPT_LEVEL not set, using default: $OPT_LEVEL"
fi

# Change to project root
cd "$PROJECT_ROOT"

# Convert to relative paths if needed
if [[ "$GUEST_DIR" == /* ]]; then
    GUEST_DIR=$(realpath --relative-to="$PROJECT_ROOT" "$GUEST_DIR" 2>/dev/null || echo "$GUEST_DIR")
fi
if [[ "$OUTPUT" == /* ]]; then
    OUTPUT=$(realpath --relative-to="$PROJECT_ROOT" "$OUTPUT" 2>/dev/null || echo "$OUTPUT")
fi

# Verify guest package exists
if [ ! -f "$GUEST_DIR/guest.c" ] || [ ! -f "$GUEST_DIR/guest.h" ]; then
    echo "Error: Guest package not found at $GUEST_DIR"
    echo "Expected files: guest.c, guest.h, w2c2_base.h"
    exit 1
fi

# Create output directory
mkdir -p "$(dirname "$OUTPUT")"

echo "======================================"
echo "C to RISC-V QEMU Compilation"
echo "======================================"
echo "Guest package: $GUEST_DIR"
echo "Output binary: $OUTPUT"
echo ""

# Compile everything in one command via Docker
echo "Compiling..."

# Compiler flags (using -O0 for faster compilation of large generated files)
CFLAGS=(
    -march=rv64imad
    -mabi=lp64d
    -mcmodel=medany
    -static
    -ffunction-sections
    -fdata-sections
    $OPT_LEVEL
)

# Include directories
INCLUDES=(
    -I"$GUEST_DIR"
    -Iw2c2/embedded
)

# Source files
SOURCES=(
    platform/riscv-qemu/main.c
    "$GUEST_DIR/guest.c"
    w2c2/embedded/wasi.c
)

riscv64-linux-gnu-gcc \
    "${CFLAGS[@]}" \
    "${INCLUDES[@]}" \
    "${SOURCES[@]}" \
    -o "$OUTPUT" -lm 2>&1

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
    echo "  qemu-riscv64 $OUTPUT"
    echo ""
else
    echo "Error: Compilation failed"
    exit 1
fi
