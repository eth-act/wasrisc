#!/bin/bash
set -e

# c2riscv-qemu.sh - Compile C package to RISC-V QEMU virt binary
# Usage: ./go-wasm-rv64/riscv-qemu/scripts/c2riscv-qemu.sh <guest-c-package-dir> <output-elf>

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
    echo "  output-elf           Output RISC-V ELF binary path"
    echo ""
    echo "Example:"
    echo "  $0 build/.c-packages/println build/bin/println.riscv.elf"
    echo ""
    echo "To run in QEMU:"
    echo "  qemu-system-riscv64 -machine virt -bios none \\"
    echo "    -kernel build/bin/println.riscv.elf -nographic \\"
    echo "    -semihosting-config enable=on,target=native"
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
echo "C to RISC-V QEMU Compilation"
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
    -march=rv64ima
    -mabi=lp64
    -mcmodel=medany
    -specs=nosys.specs
    -D__bool_true_false_are_defined
    -ffunction-sections
    -fdata-sections
    -O0
    -g
    -Wall
)

# Include directories
INCLUDES=(
    -I"$GUEST_DIR"
    -Igo-wasm-rv64/wasi/embedded
    -Igo-wasm-rv64/riscv-qemu
)

# Source files
SOURCES=(
    go-wasm-rv64/riscv-qemu/main.c
    go-wasm-rv64/riscv-qemu/syscalls.c
    "$GUEST_DIR/guest.c"
    go-wasm-rv64/wasi/embedded/wasi.c
)

# Assembly source
ASM_SOURCE=go-wasm-rv64/riscv-qemu/startup.S

# Linker script
LINKER_SCRIPT=go-wasm-rv64/riscv-qemu/virt.ld

# Linker flags (matching demo-qemu-virt-riscv/Makefile)
LDFLAGS=(
    -T"$LINKER_SCRIPT"
    -nostartfiles
    -static
    -Wl,--gc-sections
    -Wl,-Map="${OUTPUT%.elf}.map"
)

# Link libraries
LIBS=(-lc -lm -lgcc)

"$DOCKER_DIR/docker-shell.sh" ${PREFIX}gcc \
    "${CFLAGS[@]}" \
    "${INCLUDES[@]}" \
    "${SOURCES[@]}" \
    "$ASM_SOURCE" \
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
    echo "  qemu-system-riscv64 -machine virt -bios none \\"
    echo "    -kernel $OUTPUT -nographic \\"
    echo "    -semihosting-config enable=on,target=native"
    echo ""
else
    echo "Error: Compilation failed"
    exit 1
fi
