/* zkvm-specific system functions */

#include <stdint.h>
#include "zkvm.h"

/* zkvm-specific output counter */
static int outputCount = 0;

/* printk: Write value to zkvm output buffer
 * Format: [count:u32][data:bytes]
 */
void printk(uint32_t val) {
    outputCount++;
    uint32_t *ptr_count = (uint32_t *)OUTPUT_ADDR;
    *ptr_count = outputCount;

    uint32_t *ptr_val = (uint32_t *)(OUTPUT_ADDR + 4 + 4 * (outputCount - 1));
    *ptr_val = val;
}

/* len_input_buf: Get length of input buffer */
uint32_t len_input_buf() {
    uint32_t *ptr_val = (uint32_t *)(INPUT_ADDR + 4 * 2);
    uint32_t len = (*ptr_val) / 4;
    if ((*ptr_val) % 4 != 0) {
        len++;
    }
    return len;
}

/* read_value: Read value from input buffer at index i */
uint32_t read_value(uint32_t i) {
    uint32_t *ptr_val = (uint32_t *)(INPUT_ADDR + 4 * (i + 4));
    return *ptr_val;
}

/* shutdown: Signal zkvm to exit via ecall 93 */
void shutdown() {
    __asm__ volatile("li a7, 93");
    __asm__ volatile("ecall");
}
