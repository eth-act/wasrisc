#include "bh_platform.h"
#include "bh_read_file.h"
#include "wasm_export.h"
#include <stdio.h>

extern const char wasmModuleBuffer[];
extern int wasmModuleBuffer_length;

static inline unsigned long rdinstret(void) {
    unsigned long v;
    asm volatile ("csrr %0, instret" : "=r"(v));
    return v;
}

int main(void) {
    int argc = 0;
    char *argv[0];

    char error_buf[128];

    wasm_module_t module;
    wasm_module_inst_t module_inst;
    wasm_function_inst_t func;
    wasm_exec_env_t exec_env;
    uint32 size, stack_size = 16*1024*1024;
    unsigned long instrs_start, instrs_init, instrs_load, instrs_inst,
                  instrs_exec, instrs_unload, instrs_end;

    instrs_start = rdinstret();

    wasm_runtime_set_log_level(WASM_LOG_LEVEL_VERBOSE);

    /* initialize the wasm runtime by default configurations */
    if (!wasm_runtime_init()) {
        printf("runtime init failed\n");
        exit(1);
    }
    instrs_init = rdinstret();

    /* parse the WASM file from buffer and create a WASM module */
    module = wasm_runtime_load(wasmModuleBuffer, wasmModuleBuffer_length, error_buf, sizeof(error_buf));
    if (module == 0) {
        printf("runtime load module failed: %s\n", error_buf);
        exit(1);
    }
    instrs_load = rdinstret();

    /* create an instance of the WASM module (WASM linear memory is ready) */
    module_inst = wasm_runtime_instantiate(module, stack_size, 0, error_buf, sizeof(error_buf));
    if (module_inst == 0) {
        printf("wasm_runtime_instantiate failed as module_inst=%p: %s\n", module_inst, error_buf);
        exit(1);
    }
    instrs_inst = rdinstret();

    if (!wasm_application_execute_main(module_inst, argc, argv)) {
        printf("error executing main\n");
        printf("exception: %s\n", wasm_runtime_get_exception(module_inst));
    }
    instrs_exec = rdinstret();

    printf("wasm_runtime_unload...\n");
    wasm_runtime_unload(module);
    instrs_end = instrs_unload = rdinstret();

    printf("instructions runtime init:        %lu\n", instrs_init-instrs_start);
    printf("instructions runtime load:        %lu\n", instrs_load-instrs_init);
    printf("instructions runtime instantiate: %lu\n", instrs_inst-instrs_load);
    printf("instructions runtime exec:        %lu\n", instrs_exec-instrs_inst);
    printf("instructions runtime unload:      %lu\n", instrs_unload-instrs_exec);
    printf("instructions in total:            %lu\n", instrs_end-instrs_start);

    return 0;
}
