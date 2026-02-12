/* Custom WASM imports for zkvm target
 *
 * This file implements custom functions for Dotnet and Go programs. See README.md for more details.
 *
 * This will be used to implement zkvm precompiles and zkvm specific functions that the guest
 * program needs.
 *
 */

#include "w2c2_base.h"
#include <stdio.h>

U32 testmodule__testfunc(void* instance, U32 a, U32 b) {
    return 1000*a + b;
}

U32 testmodule__testfunc2(void* instance, U32 a, U32 b) {
    return a * b;
}

int testmodule__printk(void* instance, U32 val) {
    char buf[12];
    static const char hex[] = "0123456789abcdef";

    buf[0] = '0';
    buf[1] = 'x';
    for (int i = 7; i >= 0; --i) {
        buf[i+2] = hex[val & 0xF];
        val >>= 4;
    }
    buf[10] = '\n';
    buf[11] = '\0';

    puts(buf);
}

void testmodule__shutdown(void* instance) {
    exit(0);
}

U32 testmodule__inputX2DdataX2Dlen(void* instance) {
    return 0;
}

U32 testmodule__inputX2Ddata(void* instance, U32 index) {
    return 0;
}
