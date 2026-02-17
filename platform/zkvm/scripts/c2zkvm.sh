#!/bin/bash

set -e

# c2zkvm.sh - Compile C package to zkvm RISC-V binary
# Usage: ./platform/zkvm/scripts/c2zkvm.sh <guest-c-package-dir> <output-elf>

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZKVM_DIR="$(dirname "$SCRIPT_DIR")"
DOCKER_DIR="$ZKVM_DIR/../../docker"
PROJECT_ROOT="$ZKVM_DIR/../.."

# Check arguments
if [ $# -lt 2 ]; then
    echo "Usage: $0 <guest-c-package-dir> <output-elf>"
    echo ""
    echo "Compiles a C package (from w2c2) to RISC-V binary for zkvm."
    echo ""
    echo "Arguments:"
    echo "  guest-c-package-dir  Directory containing guest.c, guest.h, w2c2_base.h"
    echo "  output-elf           Output RISC-V ELF binary path"
    echo ""
    echo "Example:"
    echo "  $0 build/.c-packages/println build/bin/println.zkvm.elf"
    echo ""
    echo "To run in zkvm:"
    echo "  ziskemu -e build/bin/println.zkvm.elf --max-steps 40000000000"
    echo ""
    exit 1
fi

GUEST_DIR="$1"
OUTPUT="$2"

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
echo "C to zkvm RISC-V Compilation"
echo "======================================"
echo "Guest package: $GUEST_DIR"
echo "Output binary: $OUTPUT"
echo ""

# Compile everything in one command via Docker
echo "Compiling..."

# RISC-V toolchain prefix
PREFIX=/opt/riscv-newlib/bin/riscv64-unknown-elf-

# Compiler flags (using -O0 for faster compilation of large generated files)
CFLAGS=(
    --target=riscv64
    -march=rv64ima
    -mabi=lp64
    -mcmodel=medany
    -D__bool_true_false_are_defined
    -include stdbool.h
    -O0
    -g
    -nostdlib
    -Wno-multilib-not-found
    --sysroot=/opt/riscv-newlib/riscv64-unknown-elf
    --gcc-toolchain=/opt/riscv-newlib
)
#    -specs=nosys.specs -- not existing on clang

# TODO: build w2c2 generated code separately with -Wnoall   -Wall

# Include directories
INCLUDES=(
    -I"$GUEST_DIR"
    -Iw2c2/embedded
    -Iplatform/zkvm
)

# Source files (minimal set)
SOURCES=(
    platform/zkvm/zkvm.c
    platform/zkvm/custom_imports.c
    "$GUEST_DIR/guest.c"
    platform/zkvm/main.c
    w2c2/embedded/wasi.c
    w2c2/embedded/wasip2.c
    w2c2/embedded/memlib.c
)

# Assembly source
ASM_SOURCES=(
    platform/zkvm/startup.S
    w2c2/embedded/memops.S
)

# Linker script
LINKER_SCRIPT=platform/zkvm/zkvm.ld

# Linker flags
LDFLAGS=(
    --target=riscv64
    -march=rv64ima
    -mabi=lp64
    -mcmodel=medany
    -T"$LINKER_SCRIPT"
    -nostartfiles
    -nostdlib
    -Wno-multilib-not-found
    --sysroot=/opt/riscv-newlib/riscv64-unknown-elf
    --gcc-toolchain=/opt/riscv-newlib
)

# Link libraries
LIBS=(-lgcc -lm)

# Remove object files
rm -f $PROJECT_ROOT/custom_imports.o $PROJECT_ROOT/guest.o $PROJECT_ROOT/main.o $PROJECT_ROOT/memlib.o $PROJECT_ROOT/memops.o $PROJECT_ROOT/s00000*.o $PROJECT_ROOT/startup.o $PROJECT_ROOT/wasi.o $PROJECT_ROOT/wasip2.o $PROJECT_ROOT/zkvm.o

parallel -j$(nproc) "$PROJECT_ROOT/docker-shell.sh" clang \
    -c \
    "${CFLAGS[@]}" \
    "${INCLUDES[@]}" \
    ::: \
    "${SOURCES[@]}" \
    "${ASM_SOURCES[@]}" \
    $GUEST_DIR/s0*.c 2>&1

"$PROJECT_ROOT/docker-shell.sh" clang \
    *.o \
    "${LDFLAGS[@]}" \
    "${LIBS[@]}" \
    -o "$OUTPUT" 2>&1

# Remove object files
rm -f $PROJECT_ROOT/custom_imports.o $PROJECT_ROOT/guest.o $PROJECT_ROOT/main.o $PROJECT_ROOT/memlib.c $PROJECT_ROOT/memops.o $PROJECT_ROOT/s00000*.o $PROJECT_ROOT/startup.o $PROJECT_ROOT/wasi.o $PROJECT_ROOT/wasip2.o $PROJECT_ROOT/zkvm.o

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
    echo "To run in zisk:"
    echo "  ziskemu -e $OUTPUT"
    echo ""
else
    echo "Error: Compilation failed"
    exit 1
fi
