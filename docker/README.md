# Docker Build Environment

This Docker setup provides a complete build environment with the RISC-V GNU toolchain and w2c2 built from source.

## Building the Image

**Warning:** The initial build will take a while because it compiles the RISC-V GNU toolchain from source.

```bash
docker build -f docker/Dockerfile -t skunkworks-go-wasm .
```

## Usage

Use the wrapper script to run commands in Docker:

```bash
# Examples

# Run make all
./docker/docker-shell.sh make all

# Run gcc
./docker/docker-shell.sh riscv64-unknown-elf-gcc --version
```

Note: The wrapper script will automatically build the image if it doesn't exist.