/* Main entry point for zkvm RISC-V target */

#include <stddef.h>
#include <stdio.h>

#include "w2c2_base.h"
#include "wasi.h"
#include "guest.h"
#include "zkvm.h"

int *__errno()
{
    static int err;
    return &err;
}

size_t strlen(const char *s);

void writeuartc(const char c) {
	char *ptr_val = (char *)(0xa0000000+512);
	*ptr_val = c;
}

int putchar(int c) {
    writeuartc(c);
	return 1;
}

int puts(const char *s) {
    for (int i = 0; i < strlen(s); i++) {
        writeuartc(s[i]);
    }
    return strlen(s);
}

int printf(const char *fmt, ...) {
    for (int i = 0; i < strlen(fmt); i++) {
        writeuartc(fmt[i]);
    }
    return strlen(fmt);
}

#define strlen_max 100

size_t strlen(const char *s) {
    for (int i = 0; i < strlen_max; i++) {
        if (s[i] == 0) {
            return i;
        }
    }
    return strlen_max;
}

/* Trap handler for WASM runtime errors */
void trap(Trap trap) {
    puts("trap(..)\n");
    switch (trap) {
    case trapUnreachable:
        puts("trap: unreachable\n");
        break;
    case trapDivByZero:
        puts("trap: div by zero\n");
        break;
    case trapIntOverflow:
        puts("trap: int overflow\n");
        break;
    case trapInvalidConversion:
        puts("trap: invalid conversion\n");
        break;
    case trapAllocationFailed:
        puts("trap: allocation failed\n");
        break;
    default:
        puts("trap: code unknown\n");
    }
    shutdown();
    while (1) {}
}

void abort(void) {
    puts("abort()\n");
    shutdown();
    while (1) {}
}

void exit(int status) {
    puts("exit()\n");
    shutdown();
    while (1) {}
}

/* WASI memory accessor - returns WASM linear memory */
wasmMemory* wasiMemory(void* instance) {
    return guest_memory((guestInstance*)instance);
}

/* Environment pointer for WASI */
char** environ = NULL;

/* Main entry point */
int main(void) {
    // Initialize WASI //
    if (!wasiInit(0, NULL, environ)) {
        printf("failed to init WASI\n");
        return 1;
    }

    guestInstance instance0;

    printf("instantiating guest program...\n");
    guestInstantiate(&instance0, NULL);

    guest__start(&instance0);

    guestFreeInstance(&instance0);

    puts("guest program completed\n");

    // Explicit shutdown call needed at least for dotnet (TODO: why?)
    shutdown();

    return 0;
}
