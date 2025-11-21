#include "wasi.h"
#include "guest.h"
#include <stdio.h>
#include <stdlib.h>

void
trap(
    Trap trap
) {
    fprintf(stderr, "TRAP: %s\n", trapDescription(trap));
    abort();
}

wasmMemory*
wasiMemory(
    void* instance
) {
    return guest_memory((guestInstance*)instance);
}

char** environ = NULL;

int main(int argc, char* argv[]) {
    /* Initialize WASI */
    if (!wasiInit(argc, argv, environ)) {
        fprintf(stderr, "failed to init WASI\n");
        return 1;
    }

    {
        guestInstance instance0;

        printf("instantiating guest program...\n");
        guestInstantiate(&instance0, NULL);

        guest__start(&instance0);

        guestFreeInstance(&instance0);
    }

    printf("guest program completed\n");
    return 0;
}
