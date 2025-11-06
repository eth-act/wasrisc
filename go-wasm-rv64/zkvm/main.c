#include <stdlib.h>
#include <stdio.h>

#include "w2c2_base.h"
#include "wasi.h"
#include "zkvm.h"

#include "example.h"

#define uint32_t unsigned int
#define size_t unsigned int

wasmMemory*
wasiMemory(
	void* instance
) {
	return example_memory((exampleInstance*)instance);
}

int outputCount = 0;

// https://github.com/eth-act/skunkworks-tama/blob/main/tamaboards/zkvm/board.go
void printk(uint32_t val) {
	// TODO: This is a stub. Just write to the output address
	// Write directly to OUTPUT_ADDR
	// Format: [count:u32][data:bytes]
	// First update the count at OUTPUT_ADDR
	outputCount+=1;
	uint32_t *ptr_count = (uint32_t *)OUTPUT_ADDR;
	*ptr_count = outputCount;

	// Write the byte at OUTPUT_ADDR + 4 + (outputCount-1)
	uint32_t *ptr_val = (uint32_t *)(OUTPUT_ADDR+4+4*(outputCount-1));
	*ptr_val = val;
}

uint32_t len_input_buf() {
	uint32_t *ptr_val = (uint32_t *)(INPUT_ADDR+4*2);
	uint32_t len = (*ptr_val)/4;
	if ((*ptr_val)%4!=0) {
		len++;
	}
	return len;
}

uint32_t read_value(uint32_t i) {
	uint32_t *ptr_val = (uint32_t *)(INPUT_ADDR+4*(i+4));
	return *ptr_val;
}

// https://github.com/eth-act/skunkworks-tama/blob/main/tamaboards/zkvm/shutdown.s
void shutdown() {
	__asm__("li a7, 93");
	__asm__("ecall");
}

extern char** environ;

extern exampleInstance *wasiInstance;

int main(void) {
	int test_argc = 0;
	char **test_argv = NULL;

	// Initialize WASI
	if (!wasiInit(test_argc, test_argv, environ)) {
		fprintf(stderr, "failed to init WASI\n");
		return 0;
	}

	exampleInstance* instance0 = malloc(sizeof(exampleInstance));
	wasiInstance = instance0;

	exampleInstantiate(instance0, NULL);

    example__start(instance0);

	exampleFreeInstance(instance0);

	shutdown();
}
