FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    autoconf \
    automake \
    autotools-dev \
    curl \
    python3 \
    python3-pip \
    python3-tomli \
    libmpc-dev \
    libmpfr-dev \
    libgmp-dev \
    gawk \
    build-essential \
    bison \
    flex \
    texinfo \
    gperf \
    libtool \
    patchutils \
    bc \
    zlib1g-dev \
    libexpat-dev \
    ninja-build \
    git \
    cmake \
    libglib2.0-dev \
    libslirp-dev \
    libpthread-stubs0-dev \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Build RISC-V GNU Toolchain
RUN git clone https://github.com/riscv/riscv-gnu-toolchain /tmp/riscv-gnu-toolchain && \
    cd /tmp/riscv-gnu-toolchain && \
    ./configure \
        --prefix=/opt/riscv-newlib \
        --with-arch=rv64ima \
        --disable-gdb \
        --with-cmodel=medany && \
    make -j$(nproc) && \
    cd / && \
    rm -rf /tmp/riscv-gnu-toolchain

# Build w2c2
RUN git clone https://github.com/turbolent/w2c2.git /opt/w2c2 && \
    cd /opt/w2c2/w2c2 && \
    make

RUN apt update && apt install -y git build-essential ninja-build pkg-config libglib2.0-dev libpixman-1-dev

RUN git clone https://git.qemu.org/git/qemu.git && \
    cd qemu && \
    ./configure --target-list=riscv64-linux-user --enable-plugins && \
    make -j4 && \
    make install && \
    cp build/tests/tcg/plugins/libinsn.so /libinsn.so && \
    cd .. && \
    rm -r qemu

# Build WAMR with ZKVM platform
RUN git clone https://github.com/bytecodealliance/wasm-micro-runtime.git /opt/wamr
COPY platform/riscv-wamr-qemu/wamr-platform/ /opt/wamr/core/shared/platform/zkvm/
RUN cd /opt/wamr && \
    sed -i "s/find_package(Threads REQUIRED)/find_package(Threads)/g" CMakeLists.txt && \
    cmake . \
        -DWAMR_BUILD_PLATFORM=zkvm \
        -DWAMR_BUILD_TARGET=AOT \
        -DWAMR_BUILD_LIBC_BUILTIN=1 \
        -DWAMR_BUILD_LIB_PTHREAD=0 \
        -DWAMR_BUILD_THREAD_MGR=0 \
        -DWAMR_BUILD_WASI_THREADS=0 \
        -DTHREADS_PREFER_PTHREAD_FLAG=OFF \
        -DCMAKE_THREAD_LIBS_INIT="" \
        -DWAMR_BUILD_FAST_INTERP=1 \
        -DWAMR_BUILD_JIT=0 \
        -DWAMR_BUILD_AOT=1 \
        -DCMAKE_SYSTEM_PROCESSOR=riscv64 \
        -DWAMR_BUILD_TARGET=RISCV64_LP64 \
        -DCMAKE_C_COMPILER=/opt/riscv-newlib/bin/riscv64-unknown-elf-gcc \
        -DCMAKE_CXX_COMPILER=/opt/riscv-newlib/bin/riscv64-unknown-elf-g++ \
        -DCMAKE_ASM_COMPILER=/opt/riscv-newlib/bin/riscv64-unknown-elf-gcc \
        -DWASM_ENABLE_SIMDE=OFF \
        -DWAMR_BUILD_SIMD=0 && \
    make

# Use pre-compiled wamrc
RUN wget https://github.com/bytecodealliance/wasm-micro-runtime/releases/download/WAMR-2.4.4/wamrc-2.4.4-x86_64-ubuntu-22.04.tar.gz && \
    tar xf wamrc-2.4.4-x86_64-ubuntu-22.04.tar.gz && \
    mv wamrc /usr/local/bin/ && \
    rm wamrc-2.4.4-x86_64-ubuntu-22.04.tar.gz

# Add toolchains to PATH
ENV PATH="/opt/riscv-newlib/bin:/opt/w2c2/w2c2:${PATH}"

RUN apt update && apt install -y gcc-riscv64-linux-gnu

RUN curl https://wasmtime.dev/install.sh -sSf | bash

RUN curl https://get.wasmer.io -sSfL | sh

# Set working directory
WORKDIR /workspace

# Default command
CMD ["/bin/bash"]
