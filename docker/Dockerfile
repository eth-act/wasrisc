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
    python3.10-venv \
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

# Include patch for insn.c because otherwise this error appears due to unknown
# instructions:
#
# ERROR:../tests/tcg/plugins/insn.c:97:vcpu_init: assertion failed: (count > 0)
#
# https://lists.gnu.org/archive/html/qemu-discuss/2025-08/msg00001.html
RUN git clone https://git.qemu.org/git/qemu.git && \
    cd qemu && \
    sed -i 's/g_assert(count > 0)/g_assert(count >= 0)/g' tests/tcg/plugins/insn.c && \
    ./configure --target-list=riscv64-linux-user,riscv64-softmmu,x86_64-softmmu,i386-softmmu,x86_64-linux-user,i386-linux-user,aarch64-softmmu,aarch64-linux-user --enable-plugins && \
    make -j4 && \
    make install && \
    cp build/tests/tcg/plugins/libinsn.so /libinsn.so && \
    cd .. && \
    rm -r qemu

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
RUN git clone https://github.com/psilva261/wasm-micro-runtime-zkvm.git /opt/wamr/ && \
    cd /opt/wamr && \
    git checkout zkvm && \
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
    make && \
    cd /opt/wamr/wamr-compiler && \
    ./build_llvm.sh && \
    cmake . && \
    make

RUN apt update && apt install -y gcc-riscv64-linux-gnu
RUN apt update && apt install -y wget

RUN wget https://wasmtime.dev/install.sh \
    && chmod u+x install.sh \
    && ./install.sh --version v39.0.1 \
    && rm ./install.sh

RUN curl https://get.wasmer.io -sSfL | sh -s "v6.1.0"

RUN git clone https://github.com/richfelker/musl-cross-make \
    && cd musl-cross-make \
    && printf 'TARGET = aarch64-linux-musl\nOUTPUT = /opt/aarch64-linux-musl-gcc\n' > config.mak \
    && make -j8 \
    && make install \
    && cd .. \
    && rm -r musl-cross-make

WORKDIR /opt
RUN wget https://github.com/llvm/llvm-project/releases/download/llvmorg-21.1.8/LLVM-21.1.8-Linux-X64.tar.xz && \
   tar xf LLVM-21.1.8-Linux-X64.tar.xz && \
   rm /opt/LLVM-21.1.8-Linux-X64.tar.xz

# Add toolchains to PATH
ENV PATH="/opt/riscv-newlib/bin:/opt/LLVM-21.1.8-Linux-X64/bin:/opt/w2c2/w2c2:/opt/wamr/wamr-compiler:${PATH}"
ENV PATH="/opt/aarch64-linux-musl-gcc/bin:${PATH}"

RUN git clone https://github.com/bytecodealliance/wasm-micro-runtime /opt/wamr-aarch64/ && \
    cd /opt/wamr-aarch64 && \
    cmake . \
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
    cd /opt/wamr-aarch64/wamr-compiler && \
    ./build_llvm.sh && \
    cmake . && \
    make

RUN ln -s /opt/aarch64-linux-musl-gcc/aarch64-linux-musl/lib/libc.so /lib/ld-musl-aarch64.so.1

# https://github.com/llvm/llvm-project/issues/81440
#
# https://github.com/bytecodealliance/wasm-micro-runtime/blob/d4034f1cfbbbd5fe5e3dcf9bb10f00dca625218c/doc/build_wamr.md#configure-llvm-jit
#
# To build llvm-jit support, llvm needs to be built first
#
# TODO: look into WAMR_BUILD_LAZY_JIT={0,1}
# TODO2: just may core/deps/llvm if possible
RUN git clone https://github.com/psilva261/wasm-micro-runtime-zkvm.git /opt/wamr-llvm-jit/ && \
    cd /opt/wamr-llvm-jit && \
    git checkout zkvm && \
    cd /opt/wamr-llvm-jit/wamr-compiler && \
    ./build_llvm.sh && \
    cmake . && \
    make

WORKDIR /opt
RUN wget https://zlib.net/zlib-1.3.1.tar.gz
#WORKDIR /opt/zlib-1.3.1
#RUN bash ./configure
#RUN make
#RUN make install

ENV ZLIB_LIBRARY=/opt/zlib-1.3.1
RUN sed -i '/find_package(Threads)/a find_package(ZLIB REQUIRED)' /opt/wamr-llvm-jit/CMakeLists.txt
RUN ln -s /usr/include/asm-generic /usr/include/asm
RUN cd /opt/wamr-llvm-jit && \
    cmake . \
        -DWAMR_BUILD_PLATFORM=zkvm \
        -DWAMR_BUILD_LIBC_BUILTIN=1 \
        -DWAMR_BUILD_LIB_PTHREAD=0 \
        -DWAMR_BUILD_THREAD_MGR=0 \
        -DWAMR_BUILD_WASI_THREADS=0 \
        -DTHREADS_PREFER_PTHREAD_FLAG=OFF \
        -DCMAKE_THREAD_LIBS_INIT="" \
        -DWAMR_BUILD_FAST_INTERP=1 \
        -DWAMR_BUILD_JIT=1 \
        -DWAMR_BUILD_AOT=0 \
        -DCMAKE_SYSTEM_PROCESSOR=riscv64 \
        -DWAMR_BUILD_TARGET=RISCV64_LP64 \
        -DCMAKE_C_COMPILER=/opt/riscv-newlib/bin/riscv64-unknown-elf-gcc \
        -DCMAKE_CXX_COMPILER=/opt/riscv-newlib/bin/riscv64-unknown-elf-g++ \
        -DCMAKE_ASM_COMPILER=/opt/riscv-newlib/bin/riscv64-unknown-elf-gcc \
        -DWASM_ENABLE_SIMDE=OFF \
        -DZLIB_LIBRARY=/opt/zlib-1.3.1 \
        -DWAMR_BUILD_SIMD=0 && \
   make

# Set working directory
WORKDIR /workspace

# Default command
CMD ["/bin/bash"]
