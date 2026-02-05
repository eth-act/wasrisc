#!/bin/bash

# Docker shell wrapper - makes Docker environment transparent
# Usage: ./docker/docker-shell.sh [command]
# If no command provided, opens interactive shell

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="skunkworks-go-wasm"

# Build image if it doesn't exist
if ! docker images "$IMAGE_NAME" | grep -q "$IMAGE_NAME"; then
    echo "Image $IMAGE_NAME not found. Building..."
    docker build -f "$SCRIPT_DIR/docker/Dockerfile" -t "$IMAGE_NAME" "$SCRIPT_DIR/docker"
fi

# Run command in Docker
docker run --rm \
    -e QEMU_LOG=plugin \
    -v "$SCRIPT_DIR:/workspace" \
    -w /workspace \
    "$IMAGE_NAME" \
    "$@"
