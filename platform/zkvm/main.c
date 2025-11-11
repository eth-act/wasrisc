/* Main entry point for zkvm RISC-V target */

#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>

#include "w2c2_base.h"
#include "wasi.h"
#include "guest.h"

/* Trap handler for WASM runtime errors */
void trap(Trap trap) {
    fprintf(stderr, "TRAP: %s\n", trapDescription(trap));
    abort();
}

/* WASI memory accessor - returns WASM linear memory */
wasmMemory* wasiMemory(void* instance) {
    return guest_memory((guestInstance*)instance);
}

/* Environment pointer for WASI */
char** environ = NULL;

/* Main entry point */
int main(void) {
    /* Initialize WASI */
    if (!wasiInit(0, NULL, environ)) {
        fprintf(stderr, "failed to init WASI\n");
        return 1;
    }

    guestInstance instance0;
    printf("instantiating guest program...\n");
    guestInstantiate(&instance0, NULL);
    guest__start(&instance0);
    guestFreeInstance(&instance0);

    printf("guest program completed\n");

    return 0;
}
