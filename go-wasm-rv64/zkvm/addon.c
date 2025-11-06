#include <stddef.h>

#include "zkvm.h"

typedef enum Trap {
    trapUnreachable,
    trapDivByZero,
    trapIntOverflow,
    trapInvalidConversion,
    trapAllocationFailed
} Trap;

void trap(Trap trap) {
    printk(0x1000eeee);
}

char ** environ = {NULL};
