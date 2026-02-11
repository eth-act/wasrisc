#include <stddef.h>
#include <stdio.h>

#include "w2c2_base.h"

#define RAM_START 0xa0020000
#define RAM_SIZE 0x1FFE0000

#define HEAP_OFFSET 0x01000000 /* TODO */
#define HEAP_START (RAM_START+HEAP_OFFSET)
#define HEAP_SIZE (RAM_SIZE-HEAP_OFFSET)

// (just to experiment with optimizations, will likely break)
#define SKIP_BIG_CHUNKS_MEMSET_ZEROING

#define SKIP_ALLOC_ZEROING

// w2c2 only allocates 3 different buffers. Provide initial
// size estimates which are updated during runtime.
int wasmMemoryStructBufSize = sizeof(wasmMemory);
int wasmFunctionTableBufSize = 0x100000;
int wasmMemoryDataBufSize = 0x04490000;

bool memory_data_size_ok(size_t size) {
	return (char*)(HEAP_START + wasmMemoryStructBufSize + wasmFunctionTableBufSize + size) <= (char*)(HEAP_START + HEAP_SIZE);
}

typedef enum alloc_t {
  wasm_memory_struct_alloc = 1,
  wasm_function_table_alloc = 2,
  wasm_memory_data_alloc = 3
} alloc_t;

// Trivial malloc implementation for w2c2. It's
// called only 3 times during initialization. As an
// optimization automatically allocate a huge chunk to
// avoid subsequent realloc calls.
void *_malloc(size_t size, alloc_t alloc_type) {
    if (alloc_type == wasm_memory_struct_alloc) {
        puts("malloc: allocate wasm memory struct\n");
        return (uint32_t *)HEAP_START;
    } else if (alloc_type == wasm_function_table_alloc) {
        puts("malloc: table allocate\n");
        return (uint32_t *)(HEAP_START + HEAP_SIZE - size - 1);
    } else {
       puts("malloc: allocate memory->data\n");
       if (!memory_data_size_ok(size)) {
           puts("malloc: not enough space available\n");
           return 0;
       }
       return (uint32_t *)(HEAP_START + wasmMemoryStructBufSize);
    }
}

void *calloc(size_t nmemb, size_t size) {
    puts("calloc()\n");
    void* ptr;
    alloc_t alloc_type;

    if (size == sizeof(wasmMemory)) {
        alloc_type = wasm_memory_struct_alloc;
    } else if (size == 1) {
        alloc_type = wasm_memory_data_alloc;
        // wasmMemoryDataBufSize = size;
    } else {
        alloc_type = wasm_function_table_alloc;
        // wasmFunctionTableBufSize = size;
    }

    ptr = _malloc(nmemb*size, alloc_type);

#ifndef SKIP_ALLOC_ZEROING
    rv64_zero(ptr, nmemb*size);
#endif /* SKIP_ALLOC_ZEROING */

    return ptr;
}

// Trivial malloc implementation since the dotnet runtime
// handles memory on a higher abstraction level.
void free(void *ptr) {
    puts("free()\n");
}

void *memset(void *b, int c, size_t len);

static inline void rv64_zero(void *dst, size_t n) {
    puts("rv64_zero()\n");

    if (n == 0) return;

    memset(dst, 0, n);
}

void *realloc(void *ptr, size_t size) {
   if (!memory_data_size_ok(size)) {
       puts("realloc: not enough space available\n");
       return 0;
    }
    // wasmMemoryDataBufSize = size;
    return ptr;
}

// risc-v memcpy, memset, memmove functions
//
// memops.S (BSD-2-Clause licensed)
//
// https://github.com/avx/riscv_memops
void *_memcpy(void *dst, const void *src, size_t n);
void *_memmove(void *dest, const void *src, size_t n);
void *_memset(void *b, int c, size_t len);

void *memcpy(void *dest, const void *src, size_t n) {
    return _memcpy(dest, src, n);
}

void *memmove(void *dest, const void *src, size_t n) {
	return _memmove(dest, src, n);
}

void *memset(void *b, int c, size_t len) {
#ifdef SKIP_BIG_CHUNKS_MEMSET_ZEROING
    if (len > wasmFunctionTableBufSize && c == 0) {
        // TODO: make this dependent on initialization status of application!!!
        // perhaps even obsoleted by: https://github.com/dotnet/runtimelab/commit/cbf8308bd791f6b9610c026c83706ccace1e3be4 (Work around poor inlined memset code quality in LLVM )
        // also cf https://github.com/dotnet/runtimelab/issues/2628 Zeroing memory (for the GC) is the biggest contributor to startup in a hello world app.
        return b;
    }
#endif /* SKIP_BIG_CHUNKS_MEMSET_ZEROING */
    return _memset(b, c, len);
}
