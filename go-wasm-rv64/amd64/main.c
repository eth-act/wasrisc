#include "wasi.h"
#include "guest.h"
#include "amd64.h"
#include <stdio.h>
#include <string.h>

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

extern char** environ;

int main(int argc, char* argv[]) {
    
	test_input_data = "test789";
	test_input_data_len = strlen(test_input_data);
	if (argc == 3 && strcmp(argv[1], "-i") == 0) {
		read_input_data(argv[2]);
	}

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

    return 0;
}
