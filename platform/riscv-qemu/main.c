#include "wasi.h"
#include "guest.h"
#include "w2c2_base.h"

int *__errno()
{
    static int err;
    return &err;
}

size_t strlen(const char *s);

/* QEMU virt UART0 base address */
#define UART0_BASE 0x10000000
#define UART_TX    (*(volatile uint8_t*)(UART0_BASE + 0))
#define UART_LSR   (*(volatile uint8_t*)(UART0_BASE + 5))
#define UART_LSR_THRE (1 << 5)  /* Transmit holding register empty */

/* Simple UART output function */
static void writeuartc(char c) {
    /* Wait until transmit holding register is empty */
    while ((UART_LSR & UART_LSR_THRE) == 0);
    UART_TX = c;
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
    exit(0);
}

void abort(void) {
    puts("abort()\n");
    exit(0);
}

/* WASI memory accessor - returns WASM linear memory */
wasmMemory* wasiMemory(void* instance) {
    return guest_memory((guestInstance*)instance);
}

char** environ = NULL;

int main(int argc, char* argv[]) {
    /* Initialize WASI */
    if (!wasiInit(argc, argv, environ)) {
        printf("failed to init WASI\n");
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
