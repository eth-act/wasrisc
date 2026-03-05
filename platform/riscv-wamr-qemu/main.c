#include "wasm_export.h"
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include "uart.h"

extern const char wasmModuleBuffer[];
extern int wasmModuleBuffer_length;

void shutdown();

// risc-v memcpy, memset, memmove functions
//
// memops.S (BSD-2-Clause licensed)
//
// https://github.com/avx/riscv_memops
void *_memcpy(void *dst, const void *src, size_t n);
void *_memmove(void *dest, const void *src, size_t n);
void *_memset(void *b, int c, size_t len);

void __wrap_free(void *ptr) {
    // Trivial free
}

void *__wrap_memset(void *s, int c, size_t n) {
    // Avoid zero-ing for large allocations
    if (n > (1 << 10) && c == 0) {
        return s;
    }
    return _memset(s, c, n);
}

void *__wrap_memcpy(void *dest, const void *src, size_t n) {
    return _memcpy(dest, src, n);
}

void *__wrap_memmove(void *dest, const void *src, size_t n) {
	return _memmove(dest, src, n);
}

int main(void) {
    int argc = 0;
    char *argv[0];

    char error_buf[128];

    wasm_module_t module;
    wasm_module_inst_t module_inst;
    wasm_function_inst_t func;
    wasm_exec_env_t exec_env;
    uint32_t size, stack_size = 16*1024*1024;

    RuntimeInitArgs init_args;
    memset(&init_args, 0, sizeof(RuntimeInitArgs));

    wasm_runtime_set_log_level(WASM_LOG_LEVEL_VERBOSE);

    /* Define an array of NativeSymbol for the APIs to be exported. */
    static NativeSymbol native_symbols[] = {
        {
            "shutdown", // the name of WASM function name
            shutdown,   // the native function pointer
            "()",       // the function prototype signature, avoid to use i32
            NULL        // attachment is NULL
        },
    };

    init_args.mem_alloc_type = Alloc_With_System_Allocator;

    /* Native symbols need below registration phase */
    init_args.n_native_symbols = sizeof(native_symbols) / sizeof(NativeSymbol);
    init_args.native_module_name = "testmodule";
    init_args.native_symbols = native_symbols;

    /* initialize the wasm runtime with init_args */
    if (!wasm_runtime_full_init(&init_args)) {
        printf("runtime init failed\n");
        exit(1);
    }

    /* parse the WASM file from buffer and create a WASM module */
    module = wasm_runtime_load(wasmModuleBuffer, wasmModuleBuffer_length, error_buf, sizeof(error_buf));
    if (module == 0) {
        printf("runtime load module failed: %s\n", error_buf);
        exit(1);
    }

    /* create an instance of the WASM module (WASM linear memory is ready) */
    module_inst = wasm_runtime_instantiate(module, stack_size, 0, error_buf, sizeof(error_buf));
    if (module_inst == 0) {
        printf("wasm_runtime_instantiate failed as module_inst=%p: %s\n", module_inst, error_buf);
        exit(1);
    }

    if (!wasm_application_execute_main(module_inst, argc, argv)) {
        printf("error executing main\n");
        printf("exception: %s\n", wasm_runtime_get_exception(module_inst));
    }

    printf("wasm_runtime_unload...\n");
    wasm_runtime_unload(module);

    return 0;
}
