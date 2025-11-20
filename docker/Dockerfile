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

# Add toolchains to PATH
ENV PATH="/opt/riscv-newlib/bin:/opt/w2c2/w2c2:${PATH}"

RUN apt update && apt install -y gcc-riscv64-linux-gnu

RUN apt update && apt install -y clang lld
RUN apt update && apt install -y libc6-riscv64-cross libgcc-10-dev-riscv64-cross

# Set working directory
WORKDIR /workspace

# Default command
CMD ["/bin/bash"]
