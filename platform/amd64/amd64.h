/* amd64 target utilities */

#ifndef AMDX64_H
#define AMDX64_H

/* Test input data globals (used by custom_imports.c) */
extern char* test_input_data;
extern long test_input_data_len;

/* Read input data from file for testing */
void read_input_data(const char *filename);

#endif /* AMDX64_H */
