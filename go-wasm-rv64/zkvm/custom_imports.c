/* Custom WASM imports for zkvm target
 *
 * This file implements custom functions for Go programs using //go:wasmimport.
 * 
 * This will be used to implement zkvm precompiles and zkvm specific functions that the guest
 * program needs.
 *
 */

#include "w2c2_base.h"
#include "zkvm.h"
#include <stdio.h>

U32 testmodule__testfunc(void* instance, U32 a, U32 b) {
    return a + b;
}

U32 testmodule__testfunc2(void* instance, U32 a, U32 b) {
    return a * b;
}

void testmodule__printk(void* instance, U32 val) {
    printk(val);
}

U32 testmodule__input_data_len(void* instance) {
    uint32_t *ptr_val = (uint32_t *)(INPUT_ADDR + 4 * 2);
    return *ptr_val;
}

U32 testmodule__input_data(void* instance, U32 index) {
    return *((char *)(INPUT_ADDR + 4 * 4 + index));
}