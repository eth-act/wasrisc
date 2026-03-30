#!/bin/bash
set -e

# c2riscv-qemu-user.sh - Compile C package to RISC-V QEMU virt binary
# Usage: ./platform/riscv-qemu-user/scripts/c2riscv-qemu-user.sh <guest-c-package-dir> <output-elf>

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

if [ -n "$PGO_OPT" ]; then
    echo "Enabling profile-guided optimization"
else
	echo "PGO_OPT not set, not using profile-guided optimization"
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
echo "C to RISC-V QEMU User Compilation"
echo "======================================"
echo "Guest package: $GUEST_DIR"
echo "Output binary: $OUTPUT"
echo ""

# Compile everything in one command via Docker
echo "Compiling..."

# Compiler flags (using -O0 for faster compilation of large generated files)
CFLAGS=(
    -mcmodel=medany
    -include stdbool.h
    -mllvm -enable-misched=false
)

LDFLAGS=(
    -fuse-ld=lld
    -static
)

# Link libraries
LIBS=(-lm)

# Include directories
INCLUDES=(
    -I"$GUEST_DIR"
    -Iw2c2/embedded
)

# Source files
SOURCES=(
    platform/riscv-qemu-user/main.c
    platform/riscv-qemu-user/custom_imports.c
    "$GUEST_DIR/guest.c"
    $GUEST_DIR/s0*.c
    w2c2/embedded/wasi.c
    w2c2/embedded/wasip2.c
)

if [ -n "$PGO_OPT" ]; then
    echo ""
    echo "Generate instrumented binary: $OUTPUT.instrumented"
    echo ""

    # Remove object files
    rm -f $PROJECT_ROOT/custom_imports.o $PROJECT_ROOT/guest.o $PROJECT_ROOT/main.o $PROJECT_ROOT/memlib.o $PROJECT_ROOT/memops.o $PROJECT_ROOT/s00000*.o $PROJECT_ROOT/startup.o $PROJECT_ROOT/wasi.o $PROJECT_ROOT/wasip2.o $PROJECT_ROOT/zkvm.o

    parallel -j$(nproc) /opt/riscv-glibc-llvm/bin/clang \
        -c \
        -fprofile-instr-generate=$OUTPUT.profraw \
         --target=riscv64-unknown-linux-gnu \
        "${CFLAGS[@]}" \
        "${INCLUDES[@]}" \
        ::: \
        "${SOURCES[@]}" 2>&1

    /opt/riscv-glibc-llvm/bin/clang \
        --target=riscv64-unknown-linux-gnu \
        -fprofile-instr-generate=$OUTPUT.profraw \
        *.o \
        "${LDFLAGS[@]}" \
        "${LIBS[@]}" \
        -o "$OUTPUT.instrumented" 2>&1

    echo ""
    echo "Run instrumented binary: $OUTPUT.instrumented"
    echo ""

    qemu-riscv64 "$OUTPUT.instrumented"

    /opt/riscv-glibc-llvm/bin/llvm-profdata merge -output=$OUTPUT.profdata $OUTPUT.profraw
fi

echo ""
echo "Compile binary..."
echo ""

# Remove object files
rm -f $PROJECT_ROOT/custom_imports.o $PROJECT_ROOT/guest.o $PROJECT_ROOT/main.o $PROJECT_ROOT/memlib.o $PROJECT_ROOT/memops.o $PROJECT_ROOT/s00000*.o $PROJECT_ROOT/startup.o $PROJECT_ROOT/wasi.o $PROJECT_ROOT/wasip2.o $PROJECT_ROOT/zkvm.o

COMMON_FLAGS=(
    $OPT_LEVEL
)

if [ -n "$PGO_OPT" ]; then
    COMMON_FLAGS+=(
        -fprofile-instr-use=$OUTPUT.profdata
    )
fi

parallel -j$(nproc) /opt/riscv-glibc-llvm/bin/clang \
    -c \
     --target=riscv64-unknown-linux-gnu \
    "${COMMON_FLAGS[@]}" \
    "${CFLAGS[@]}" \
    "${INCLUDES[@]}" \
    ::: \
    "${SOURCES[@]}" 2>&1

/opt/riscv-glibc-llvm/bin/clang \
    --target=riscv64-unknown-linux-gnu \
    *.o \
    "${COMMON_FLAGS[@]}" \
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
    echo "  qemu-riscv64 $OUTPUT"
    echo ""
else
    echo "Error: Compilation failed"
    exit 1
fi
