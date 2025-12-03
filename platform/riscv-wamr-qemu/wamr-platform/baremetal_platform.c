/*
 * Copyright (C) 2019 Intel Corporation.  All rights reserved.
 * SPDX-FileCopyrightText: 2024 Siemens AG (For Zephyr usermode changes)
 * SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
 */

#include "platform_api_vmcore.h"
#include "platform_api_extension.h"

#define OUTPUT_ADDR 0xa0010000

void writeuartc(const char c) {
	char *ptr_val = (char *)(0xa0000000+512);
	*ptr_val = c;
}

int outputCount = 0;

// https://github.com/eth-act/skunkworks-tama/blob/main/tamaboards/zkvm/board.go
void printk(uint32_t val) {
	// TODO: This is a stub. Just write to the output address
	// Write directly to OUTPUT_ADDR
	// Format: [count:u32][data:bytes]
	// First update the count at OUTPUT_ADDR
	outputCount+=1;
	uint32_t *ptr_count = (uint32_t *)OUTPUT_ADDR;
	*ptr_count = outputCount;

	// Write the byte at OUTPUT_ADDR + 4 + (outputCount-1)
	uint32_t *ptr_val = (uint32_t *)(OUTPUT_ADDR+4+4*(outputCount-1));
	*ptr_val = val;
}

static int
_stdout_hook_iwasm(int c)
{
    printk((int32_t) c);
    return 1;
}

int
os_thread_sys_init();

void
os_thread_sys_destroy();

void *
os_malloc(unsigned size)
{
    return malloc(size);
}

void *
os_realloc(void *ptr, unsigned size)
{
    return realloc(ptr, size);
}

void
os_free(void *ptr)
{
    free(ptr);
}

int
os_dumps_proc_mem_info(char *out, unsigned int size)
{
    return -1;
}

#if 0
struct out_context {
    int count;
};

typedef int (*out_func_t)(int c, void *ctx);

static int
char_out(int c, void *ctx)
{
    struct out_context *out_ctx = (struct out_context*)ctx;
    out_ctx->count++;
    return _stdout_hook_iwasm(c);
}

int
os_vprintf(const char *fmt, va_list ap)
{
#if 0
    struct out_context ctx = { 0 };
    cbvprintf(char_out, &ctx, fmt, ap);
    return ctx.count;
#else
    vprintk(fmt, ap);
    return 0;
#endif
}
#endif

int
os_printf(const char *format, ...)
{
    int ret = 0;
    va_list ap;

    va_start(ap, format);
#ifndef BH_VPRINTF
    ret += vprintf(format, ap);
#else
    ret += BH_VPRINTF(format, ap);
#endif
    va_end(ap);

    return ret;
}

int
os_vprintf(const char *format, va_list ap)
{
#ifndef BH_VPRINTF
    return vprintf(format, ap);
#else
    return BH_VPRINTF(format, ap);
#endif
}

void *
os_mmap(void *hint, size_t size, int prot, int flags, os_file_handle file)
{
    void *addr;

    if ((uint64)size >= UINT32_MAX)
        return NULL;

    addr = BH_MALLOC(size);

    if (addr)
        memset(addr, 0, size);
    return addr;
}

int
os_getpagesize(void)
{
    return 4096;
}


void *
os_mremap(void *old_addr, size_t old_size, size_t new_size)
{
    return os_mremap_slow(old_addr, old_size, new_size);
}

void
os_munmap(void *addr, size_t size)
{
    BH_FREE(addr);
}

int
os_mprotect(void *addr, size_t size, int prot)
{
    return 0;
}

void
os_dcache_flush()
{}

void
os_icache_flush(void *start, size_t len)
{}

os_raw_file_handle
os_invalid_raw_handle(void)
{
    return -1;
}
