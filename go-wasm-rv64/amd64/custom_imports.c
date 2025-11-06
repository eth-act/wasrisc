#include "w2c2_base.h"
#include <stdio.h>

void testmodule__testfunc(void* p, U32 a, U32 b) {
	printf("testmodule__testfunc(%p, %x, %x, %x)\n", p, a, b);
}

// call printk directly from Go code
void testmodule__printk(void* p, int x) {
	printf("PRINTK(%x)\n", x);
}

char* test_input_data;
int test_input_data_len;

U32 testmodule__input_data(void *i, U32 k) {
	return test_input_data[k];
}

U32 testmodule__input_data_len() {
	return test_input_data_len;
}
