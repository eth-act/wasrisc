/* amd64-specific utilities */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "amd64.h"

/* Test input data globals */
char* test_input_data = NULL;
long test_input_data_len = 0;

/* Read input data from file for testing
 * Used to load test data that can be accessed via custom WASM imports
 */
void read_input_data(const char *filename) {
	FILE *f;

	f = fopen(filename, "rb");
	if (!f) {
		printf("failed to open %s\n", filename);
		return;
	}

	fseek(f, 0, SEEK_END);
	test_input_data_len = ftell(f);
	rewind(f);

	test_input_data = calloc(sizeof(char), test_input_data_len + 1);
	if (!test_input_data) {
		fclose(f);
		printf("calloc failed");
		return;
	}

	if (fread(test_input_data, test_input_data_len, 1, f) != 1) {
		fclose(f);
		printf("read failed");
		return;
	}

	fclose(f);
}
