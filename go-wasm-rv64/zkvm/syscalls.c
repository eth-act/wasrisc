#include <sys/stat.h>
#include <sys/types.h>
#include <errno.h>
#include <unistd.h>
#include <stdio.h>

#include "example.h"
#include "zkvm.h"

void writeuartc(const char c) {
	char *ptr_val = (char *)(0xa0000000+512);
	*ptr_val = c;
}

exampleInstance *wasiInstance = 0;

int _write(int file, char *ptr, int len) {
    for (int i = 0; i < len; i++) {
        writeuartc(ptr[i]);
    }
    return len;
}

int _read(int file, char *ptr, int len) {
    if (file != STDIN_FILENO) {
        errno = EBADF;
        return -1;
    }

    int i;
    for (i = 0; i < len; i++) {
    }
    return i;
}

int _open(const char *name, int flags, int mode) {
    return -1;
}

int _close(int file) {
    return -1;
}

int _lseek(int file, int ptr, int dir) { return 0; }

int _fstat(int file, struct stat *st) {
    st->st_mode = S_IFCHR;
    return 0;
}

int _isatty(int file) {
    return 1;
}

void* _sbrk(uint32_t incr) {
    static char *heap_end = (char*)HEAP_START;
    char *prev_heap_end = heap_end;

    if (heap_end + incr > (char*)(HEAP_START + HEAP_SIZE)) {
        errno = ENOMEM;
        return (void*) -1; // Return error
    }

    heap_end += incr;
    return (void*) prev_heap_end;
}

// Required stubs
void _exit(int code) {
	printf("exit code: %d\n", code);
	shutdown();
}
int _kill(int pid, int sig) { return -1; }
int _getpid(void) { return 1; }
