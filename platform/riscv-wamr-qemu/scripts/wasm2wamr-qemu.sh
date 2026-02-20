#!/bin/bash
set -e

# wasm2riscv-wamr-qemu - Compile WASM to WAMR RISC-V QEMU binary
# Usage: ./platform/riscv-wamr-qemu/scripts/wasm2riscv-wamr-qemu.sh <guest-c-package-dir> <output-elf>

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WAMR_QEMU_DIR="$(dirname "$SCRIPT_DIR")"
DOCKER_DIR="$WAMR_QEMU_DIR/../../docker"
PROJECT_ROOT="$WAMR_QEMU_DIR/../.."
WAMR_ROOT=/opt/wamr-riscv
PATH=$WAMR_ROOT/bin/:$PATH



# Check arguments
if [ $# -lt 2 ]; then
    echo "Usage: $0 <guest-c-package-dir> <output-elf>"
    echo ""
    echo "Compiles a C package (from w2c2) to WAMR-based RISC-V binary for QEMU virt machine."
    echo ""
    echo "Arguments:"
    echo "  guest-c-package-dir  Directory containing guest.c, guest.h, w2c2_base.h"
    echo "  output-elf           Output RISC-V ELF binary path"
    echo ""
    echo "Example:"
    echo "  $0 examples/build-wasm/go/println.wasm build/bin/println.wamr.elf"
    echo ""
    echo "To run in QEMU:"
    echo "  ./docker/docker-shell.sh qemu-system-riscv64 -machine virt \\"
    echo "    -m 1024M -d plugin -plugin /libinsn.so \\"
    echo "    -kernel build/bin/println.wamr.elf -nographic \\"
    echo "    -semihosting-config enable=on,target=native"
    echo ""
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

## Verify guest package exists
#if [ ! -f "$INPUT_WASM/guest.c" ] || [ ! -f "$GU#EST_DIR/guest.h" ]; then
#    echo "Error: Guest package not found at $GU#EST_DIR"
#    echo "Expected files: guest.c, guest.h, w2c#2_base.h"
#    exit 1
#fi

# Create output directory
mkdir -p "$(dirname "$OUTPUT")"

echo "======================================"
echo "WASM to WAMR RISC-V QEMU Compilation"
echo "======================================"
echo "Guest package: $INPUT_WASM"
echo "Output binary: $OUTPUT"
echo ""

# Bundle wasm binary within output elf
#
# Without --bounds-checks=1 an error
#
# runtime: morestack on g0
#
# is shown. Enabling it seems to trigger a calculation of
# the stack boundary
#
# https://github.com/bytecodealliance/wasm-micro-runtime/issues/3966
# https://github.com/bytecodealliance/wasm-micro-runtime/pull/3967
wamrc \
    --target=riscv64 \
    --target-abi=lp64 \
    --cpu=generic-rv64 \
    --cpu-features='+i,+m,+a' \
    --opt-level=0 \
    --size-level=1 \
    --bounds-checks=0 \
    -o $OUTPUT.riscv64.wamr $1

gcc platform/riscv-wamr-qemu/file2c/file2c.c \
    -o platform/riscv-wamr-qemu/file2c/file2c

# The byte buffer can be WASM binary data when
# interpreter or JIT is enabled, or AOT binary
# data when AOT is enabled.
#
# https://github.com/bytecodealliance/wasm-micro-runtime/blob/main/core/iwasm/include/wasm_export.h
platform/riscv-wamr-qemu/file2c/file2c \
    $OUTPUT.riscv64.wamr \
    wasmModuleBuffer > $OUTPUT.riscv64.wamr.c

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
    -I"$WAMR_ROOT/include"
    -Iwasi/embedded
    -Iplatform/riscv-qemu
)

# Source files
SOURCES=(
    platform/riscv-wamr-qemu/main.c
    platform/riscv-wamr-qemu/syscalls.c
    platform/riscv-wamr-qemu/uart.c
    "$OUTPUT.riscv64.wamr.c"
)

# Assembly source
ASM_SOURCE=platform/riscv-wamr-qemu/startup.S

# Linker script
LINKER_SCRIPT=platform/riscv-wamr-qemu/virt.ld

# Linker flags (matching demo-qemu-virt-riscv/Makefile)
LDFLAGS=(
    -T"$LINKER_SCRIPT"
    -nostartfiles
    -static
    -L"$WAMR_ROOT/lib"
    -liwasm
    -Wl,--gc-sections
    -Wl,-Map="${OUTPUT%.elf}.map"
)

# Link libraries
LIBS=(-lc -lm -lgcc)

${PREFIX}gcc \
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
    echo "  ./docker-shell.sh qemu-system-riscv64 -machine virt \\"
    echo "    -m 1024M -d plugin -plugin /libinsn.so \\"
    echo "    -kernel $OUTPUT -nographic \\"
    echo "    -semihosting-config enable=on,target=native"
    echo ""
else
    echo "Error: Compilation failed"
    exit 1
fi

