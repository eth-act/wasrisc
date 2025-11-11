#ifndef ZKVM_H
#define ZKVM_H

#include <stdint.h>

#define INPUT_ADDR 0x90000000
#define OUTPUT_ADDR 0xa0010000

#define RAM_START 0xa0020000
#define RAM_SIZE 0x1FFE0000

#define HEAP_OFFSET 0x01000000 /* 16 MB */
#define HEAP_START (RAM_START+HEAP_OFFSET)
#define HEAP_SIZE (RAM_SIZE-HEAP_OFFSET)

/* zkvm system functions */
void printk(uint32_t val);
uint32_t len_input_buf();
uint32_t read_value(uint32_t i);
void shutdown();

#endif
