/* Custom WASM imports for zkvm target
 *
 * This file implements custom functions for Dotnet and Go programs. See README.md for more details.
 *
 * This will be used to implement zkvm precompiles and zkvm specific functions that the guest
 * program needs.
 *
 */

#include "w2c2_base.h"
#include "zkvm.h"
#include <stdio.h>

U32 testmodule__testfunc(void* instance, U32 a, U32 b) {
    return 1000*a + b;
}

U32 testmodule__testfunc2(void* instance, U32 a, U32 b) {
    return a * b;
}

void testmodule__printk(void* instance, U32 val) {
    printk(val);
}

void testmodule__shutdown(void* instance) {
    shutdown();
}

U32 testmodule__inputX2DdataX2Dlen(void* instance) {
    uint32_t *ptr_val = (uint32_t *)(INPUT_ADDR + 4 * 2);
    return *ptr_val;
}

U32 testmodule__inputX2Ddata(void* instance, U32 index) {
    return *((char *)(INPUT_ADDR + 4 * 4 + index));
}