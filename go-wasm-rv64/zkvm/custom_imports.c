#include "w2c2_base.h"
#include "zkvm.h"
#include <stdio.h>

void testmodule__memanalysis(void *p) {
	printf("mem analysis() start...\n");
	//uint32_t i = RAM_START + RAM_SIZE/2;
	for (uint32_t i = RAM_START; i+256 < RAM_START + RAM_SIZE; i+=64*1024*1024) {
		for (uint32_t j = 0; j < 256; j+=32) {
			uint32_t *p0 = (uint32_t *)(i+j);
			uint32_t *p1 = (uint32_t *)(i+j+4);
			uint32_t *p2 = (uint32_t *)(i+j+8);
			uint32_t *p3 = (uint32_t *)(i+j+12);
			uint32_t *p4 = (uint32_t *)(i+j+16);
			uint32_t *p5 = (uint32_t *)(i+j+20);
			uint32_t *p6 = (uint32_t *)(i+j+24);
			uint32_t *p7 = (uint32_t *)(i+j+28);
			printf("@%x: %x %x %x %x %x %x %x %x\n", i+j, *p0, *p1, *p2, *p3, *p4, *p5, *p6, *p7);
		}
		printf("\n...\n\n");
	}
	printf("mem analysis() done...\n");
}

void testmodule__testfunc(void* p, U32 a, U32 b) {
	printf("testmodule__testfunc(%p, %x, %x, %x)\n", p, a, b);
	int64_t result;

	__asm__ volatile(
		"add %0, %1, %2\n"
		: "=r"(result)  /* output */
		: "r"(a), "r"(b)  /* inputs */
		: /* no clobbers */);

	printf("  result of adding %x and %x: %x\n", a, b, result);
}

// call printk directly from C# code
void testmodule__printk(void* p, int x) {
	printk(x);
}

U32 testmodule__input_data_len() {
	uint32_t *ptr_val = (uint32_t *)(INPUT_ADDR+4*2);
	uint32_t len = (*ptr_val);
	return len;
}

U32 testmodule__input_data(void *i, U32 k) {
	return *((char *)(INPUT_ADDR + 4*4 + k));
}
