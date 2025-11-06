#ifndef DOTNET_ZKVM_H
#define DOTNET_ZKVM_H

#include <stdint.h>

//#define INPUT_ADDR 0xa0000000
#define INPUT_ADDR 0x90000000
#define OUTPUT_ADDR 0xa0010000

#define RAM_START 0xa0020000
#define RAM_SIZE 0x1FFE0000

#define HEAP_OFFSET 0x01000000 /* 16 MB TODO */
#define HEAP_START (RAM_START+HEAP_OFFSET)
#define HEAP_SIZE (RAM_SIZE-HEAP_OFFSET)

void printk(uint32_t val);
void shutdown();

void set_runtime_ready();
bool get_runtime_ready();

#endif
