#include "w2c2_base.h"
#include "amd64.h"
#include <stdio.h>

U32 testmodule__testfunc(void* p, U32 a, U32 b) {
	printf("testmodule__testfunc(%p, %x, %x)\n", p, a, b);
	return a + b;
}

U32 testmodule__testfunc2(void* p, U32 a, U32 b) {
	printf("testmodule__testfunc2(%p, %x, %x)\n", p, a, b);
	return a * b;
}

// call printk directly from Go code
void testmodule__printk(void* p, int x) {
	printf("PRINTK(%x)\n", x);
}

U32 testmodule__input_data(void *i, U32 k) {
	return test_input_data[k];
}

U32 testmodule__input_data_len() {
	return test_input_data_len;
}
