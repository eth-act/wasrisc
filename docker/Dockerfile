FROM ubuntu:24.04 AS base

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    autoconf \
    automake \
    autotools-dev \
    curl \
    python3 \
    python3-pip \
    python3-tomli \
    python3.12-venv \
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
    g++-multilib \
    libgcc-9-dev \
    lib32gcc-9-dev \
    ccache \
    git \
    build-essential \
    ninja-build \
    pkg-config \
    libglib2.0-dev \
    libpixman-1-dev \
    wget \
    jq \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y \
    gcc-riscv64-linux-gnu \
    && rm -rf /var/lib/apt/lists/*

# Stage for building LLVM Toolchain
FROM base AS llvm-builder

WORKDIR /tmp

RUN git clone --depth 1 --branch llvmorg-21.1.8 https://github.com/llvm/llvm-project.git llvm && \
    cd llvm && \
    cmake -S llvm -B build -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/opt/llvm-21 \
        -DLLVM_ENABLE_PROJECTS="clang;lld" \
        -DLLVM_TARGETS_TO_BUILD="RISCV;AArch64;X86;WebAssembly" \
        -DLLVM_BUILD_LLVM_DYLIB=ON \
        -DLLVM_LINK_LLVM_DYLIB=ON \
        -DLLVM_BUILD_TESTS=OFF \
        -DLLVM_INCLUDE_TESTS=OFF \
        -DLLVM_BUILD_EXAMPLES=OFF \
        -DLLVM_INCLUDE_EXAMPLES=OFF \
        -DLLVM_ENABLE_ASSERTIONS=OFF \
        -DLLVM_INCLUDE_DOCS=OFF \
        -DLLVM_ENABLE_BINDINGS=OFF \
        -DCLANG_ENABLE_STATIC_ANALYZER=OFF \
        -DCLANG_ENABLE_ARCMT=OFF \
        -DLLVM_INSTALL_TOOLCHAIN_ONLY=ON && \
    cmake --build build --target install && \
    find /opt/llvm-21 -type f -executable -exec strip --strip-debug {} + 2>/dev/null || true && \
    find /opt/llvm-21 -name "*.a" -exec strip --strip-debug {} + 2>/dev/null || true && \
    find /opt/llvm-21 -name "*.so*" -exec strip --strip-debug {} + 2>/dev/null || true && \
    cd / && \
    rm -rf /tmp/llvm

# Stage for building RISC-V GNU Toolchain
FROM base AS riscv-gnu-builder

WORKDIR /tmp

RUN git clone https://github.com/riscv/riscv-gnu-toolchain riscv-gnu-toolchain && \
    cd riscv-gnu-toolchain && \
    git checkout 311e70f6c55953a624ca670de7c85af38c2b23c2 && \
    CFLAGS="-O2 -g0" CXXFLAGS="-O2 -g0" ./configure \
        --prefix=/opt/riscv-newlib \
        --with-arch=rv64ima \
        --disable-gdb \
        --with-cmodel=medany \
        --enable-strip && \
    make -j$(nproc) && \
    find /opt/riscv-newlib -type f -executable -exec strip --strip-debug {} + 2>/dev/null || true && \
    find /opt/riscv-newlib -name "*.a" -exec strip --strip-debug {} + 2>/dev/null || true && \
    find /opt/riscv-newlib -name "*.so" -exec strip --strip-debug {} + 2>/dev/null || true && \
    cd / && \
    rm -rf /tmp/riscv-gnu-toolchain

# Stage for building AARCH64 GCC MUSL Toolchain
FROM base AS aarch64-musl-builder

WORKDIR /tmp

RUN git clone --depth 1 https://github.com/richfelker/musl-cross-make musl-cross-make && \
    cd musl-cross-make && \
    printf 'TARGET = aarch64-linux-musl\n' > config.mak && \
    printf 'OUTPUT = /opt/aarch64-linux-musl-gcc\n' >> config.mak && \
    printf 'COMMON_CONFIG += CFLAGS="-g0 -O2" CXXFLAGS="-g0 -O2"\n' >> config.mak && \
    make -j$(nproc) && \
    make install && \
    find /opt/aarch64-linux-musl-gcc -type f -executable -exec strip --strip-debug {} + 2>/dev/null || true && \
    find /opt/aarch64-linux-musl-gcc -name "*.a" -exec strip --strip-debug {} + 2>/dev/null || true && \
    find /opt/aarch64-linux-musl-gcc -name "*.so*" -exec strip --strip-debug {} + 2>/dev/null || true && \
    cd / && \
    rm -rf /tmp/musl-cross-make

# Stage for building QEMU
FROM base AS qemu-builder

WORKDIR /tmp

RUN git clone https://git.qemu.org/git/qemu.git && \
    cd qemu && \
    git checkout 948ffdd79b78702239aace2d32d4f581913299b3 && \
    sed -i 's/g_assert(count > 0)/g_assert(count >= 0)/g' tests/tcg/plugins/insn.c && \
    CFLAGS="-O2 -g0" CXXFLAGS="-O2 -g0" ./configure \
       --target-list=riscv64-linux-user,riscv64-softmmu,x86_64-softmmu,i386-softmmu,x86_64-linux-user,i386-linux-user,aarch64-softmmu,aarch64-linux-user --enable-plugins && \
    make -j4 && \
    make install DESTDIR=/opt/qemu-install && \
    cp build/tests/tcg/plugins/libinsn.so /opt/qemu-install/libinsn.so && \
    cd / && \
    rm -rf /tmp/qemu

# Stage for building WAMR with ZKVM platform
FROM base AS wamr-riscv-builder

COPY --from=riscv-gnu-builder /opt/riscv-newlib /opt/riscv-newlib

ENV PATH="/opt/riscv-newlib/bin:${PATH}"

WORKDIR /tmp

# Build WAMR with ZKVM platform
#
# Some symbols such as __floatundisf, __floatdisf, __ltsf2 need to be
# explicitly registered for working soft float support on the target
# platform
#
# https://github.com/bytecodealliance/wasm-micro-runtime/issues/418
# https://github.com/bytecodealliance/wasm-micro-runtime/issues/531
#
# Additionally use LLVM 20. Profiling wamrc when compiling a large wasm
# file like stateless.wasm shows that AttemptToFoldSymbolOffsetDifference
# consumes most of the compile time. LLVM 19 contains a fix for this
# though. Also large code model is in principle supported for RISC-V
# since version 20.
#
# https://github.com/llvm/llvm-project/issues/81440
RUN git clone --branch zkvm https://github.com/psilva261/wasm-micro-runtime-zkvm.git wamr-riscv && \
    cd wamr-riscv && \
    git checkout a93ff4cbbf99d35869fac3e03a012e58fc6cfb9c && \
    cmake . \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/opt/wamr-riscv \
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
    make && \
    make install && \
    cd wamr-compiler && \
    ./build_llvm.sh && \
    cmake . -DCMAKE_INSTALL_PREFIX=/opt/wamr-riscv && \
    make && \
    make install && \
    cd / && \
    rm -rf /tmp/wamr-riscv

# Stage for building WAMR for aarch64
FROM base AS wamr-aarch64-builder

COPY --from=aarch64-musl-builder /opt/aarch64-linux-musl-gcc /opt/aarch64-linux-musl-gcc

ENV PATH="/opt/aarch64-linux-musl-gcc/bin:${PATH}"

WORKDIR /tmp

RUN git clone https://github.com/bytecodealliance/wasm-micro-runtime wamr-aarch64 && \
    cd wamr-aarch64 && \
    git checkout d7459e80e8c66af9065af009e6a697fc2bfd430e && \
    cmake . \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/opt/wamr-aarch64 \
        -DWAMR_BUILD_PLATFORM=linux \
        -DWAMR_BUILD_TARGET=AARCH64 \
        -DWAMR_BUILD_LIBC_BUILTIN=1 \
        -DWAMR_BUILD_LIBC_WASI=1 \
        -DWAMR_BUILD_FAST_INTERP=1 \
        -DWAMR_BUILD_JIT=0 \
        -DWAMR_BUILD_AOT=1 \
        -DCMAKE_C_COMPILER=/opt/aarch64-linux-musl-gcc/bin/aarch64-linux-musl-gcc \
        -DCMAKE_CXX_COMPILER=/opt/aarch64-linux-musl-gcc/bin/aarch64-linux-musl-g++ \
        -DCMAKE_ASM_COMPILER=/opt/aarch64-linux-musl-gcc/bin/aarch64-linux-musl-gcc \
        -DWASM_ENABLE_SIMDE=OFF \
        -DWAMR_BUILD_SIMD=0 && \
    make && \
    make install && \
    cd wamr-compiler && \
    ./build_llvm.sh && \
    cmake . -DCMAKE_INSTALL_PREFIX=/opt/wamr-aarch64 && \
    make && \
    make install && \
    cd / && \
    rm -rf /tmp/wamr-aarch64

# Stage for building w2c2
FROM base AS w2c2-builder

WORKDIR /tmp

RUN git clone https://github.com/turbolent/w2c2.git w2c2 && \
    cd w2c2/w2c2 && \
    git checkout 2a31254683de4a3f6a750c123daa7ddf97631c69 && \
    make

# Stage for Go installation
FROM base AS go-installer

WORKDIR /tmp

RUN wget -q https://go.dev/dl/go1.25.6.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.25.6.linux-amd64.tar.gz && \
    rm go1.25.6.linux-amd64.tar.gz

# Stage for Rust installation
FROM base AS rust-installer

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable

ENV PATH="/root/.cargo/bin:${PATH}"

RUN rustup target add riscv64gc-unknown-linux-gnu && \
    rustup target add aarch64-unknown-linux-musl && \
    rustup target add x86_64-unknown-linux-musl && \
    rustup target add wasm32-wasip1

# Stage for Wasmtime installation
FROM base AS wasmtime-installer

WORKDIR /tmp

RUN wget -q https://wasmtime.dev/install.sh \
    && chmod u+x install.sh \
    && ./install.sh --version v39.0.1 \
    && rm ./install.sh

# Stage for Wasmer installation
FROM base AS wasmer-installer

RUN curl https://get.wasmer.io -sSfL | sh -s "v6.1.0"

# Stage for WASI SDK installation
FROM base AS wasi-sdk-installer

WORKDIR /tmp

RUN wget -q https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-29/wasi-sdk-29.0-x86_64-linux.tar.gz && \
    tar xf wasi-sdk-29.0-x86_64-linux.tar.gz -C /opt && \
    rm wasi-sdk-29.0-x86_64-linux.tar.gz

# Final stage - assemble everything
FROM base AS final

WORKDIR /opt

# Copy all built toolchains and tools
COPY --from=llvm-builder /opt/llvm-21 /opt/llvm-21
COPY --from=riscv-gnu-builder /opt/riscv-newlib /opt/riscv-newlib
COPY --from=aarch64-musl-builder /opt/aarch64-linux-musl-gcc /opt/aarch64-linux-musl-gcc
COPY --from=qemu-builder /opt/qemu-install/usr/local /usr/local
COPY --from=qemu-builder /opt/qemu-install/libinsn.so /libinsn.so
COPY --from=wamr-riscv-builder /opt/wamr-riscv /opt/wamr-riscv
COPY --from=wamr-aarch64-builder /opt/wamr-aarch64 /opt/wamr-aarch64
COPY --from=w2c2-builder /tmp/w2c2 /opt/w2c2
COPY --from=go-installer /usr/local/go /usr/local/go
COPY --from=rust-installer /root/.cargo /root/.cargo
COPY --from=rust-installer /root/.rustup /root/.rustup
COPY --from=wasmtime-installer /root/.wasmtime /root/.wasmtime
COPY --from=wasmer-installer /root/.wasmer /root/.wasmer
COPY --from=wasi-sdk-installer /opt/wasi-sdk-29.0-x86_64-linux /opt/wasi-sdk-29.0-x86_64-linux

# Create symlink for aarch64 musl
RUN ln -s /opt/aarch64-linux-musl-gcc/aarch64-linux-musl/lib/libc.so /lib/ld-musl-aarch64.so.1

# Set up all environment variables
ENV PATH="/opt/llvm-21/bin:/opt/riscv-newlib/bin:/opt/aarch64-linux-musl-gcc/bin:/usr/local/go/bin:/root/.cargo/bin:/root/.wasmtime/bin:/root/.wasmer/bin:/opt/w2c2/w2c2:${PATH}"
ENV WASI_SYSROOT=/opt/wasi-sdk-29.0-x86_64-linux/share/wasi-sysroot

# Set working directory
WORKDIR /workspace

# Default command
CMD ["/bin/bash"]
