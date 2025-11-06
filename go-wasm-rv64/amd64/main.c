#include "wasi.h"
#include "example.h"
#include <stdio.h>

void
trap(
    Trap trap
) {
    fprintf(stderr, "TRAP: %s\n", trapDescription(trap));
    abort();
}

wasmMemory*
wasiMemory(
    void* instance
) {
    return example_memory((exampleInstance*)instance);
}

extern char** environ;

extern char* test_input_data;
extern long test_input_data_len;

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

	test_input_data = calloc(sizeof(char), test_input_data_len+1);
	if (!test_input_data) {
		fclose(f);
		printf("calloc failed");
	}

	if (fread(test_input_data, test_input_data_len, 1, f) != 1) {
		fclose(f);
		printf("read failed");
	}

	fclose(f);
}

int main(int argc, char* argv[]) {
	test_input_data = "test789";
	test_input_data_len = strlen(test_input_data);
	if (argc == 3 && strcmp(argv[1], "-i") == 0) {
		read_input_data(argv[2]);
	}

    /* Initialize WASI */
    if (!wasiInit(argc, argv, environ)) {
        fprintf(stderr, "failed to init WASI\n");
        return 1;
    }

    {
        exampleInstance instance0;

        printf("instantiate example...\n");
        exampleInstantiate(&instance0, NULL);

        example__start(&instance0);



        exampleFreeInstance(&instance0);
    }

    return 0;
}
