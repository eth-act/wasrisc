#include "wasm_export.h"
#include <stdio.h>
#include <stdint.h>

extern const char wasmModuleBuffer[];
extern int wasmModuleBuffer_length;

int main(void) {
    int argc = 0;
    char *argv[0];

    char error_buf[128];

    wasm_module_t module;
    wasm_module_inst_t module_inst;
    wasm_function_inst_t func;
    wasm_exec_env_t exec_env;
    uint32_t size, stack_size = 16*1024*1024;

    wasm_runtime_set_log_level(WASM_LOG_LEVEL_VERBOSE);

    /* initialize the wasm runtime by default configurations */
    if (!wasm_runtime_init()) {
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
