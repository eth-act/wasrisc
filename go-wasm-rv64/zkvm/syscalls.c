/* Newlib syscall stubs for zkvm RISC-V bare metal */

#include <sys/stat.h>
#include <sys/types.h>
#include <errno.h>
#include <unistd.h>
#include <stdio.h>
#include <stdint.h>

#include "zkvm.h"

/* zkvm UART output at specific memory address */
void writeuartc(const char c) {
    char *ptr_val = (char *)(0xa0000000+512);
    *ptr_val = c;
}

/* _write: Write to a file
 * For zkvm, we write to the custom UART
 */
__attribute__((used))
int _write(int file, char *ptr, int len) {
    int i;

    /* Only support stdout (1) and stderr (2) */
    if (file != STDOUT_FILENO && file != STDERR_FILENO) {
        errno = EBADF;
        return -1;
    }

    for (i = 0; i < len; i++) {
        writeuartc(ptr[i]);
    }
    return len;
}

/* _read: Read from a file
 * Not implemented for zkvm
 */
__attribute__((used))
int _read(int file, char *ptr, int len) {
    if (file != STDIN_FILENO) {
        errno = EBADF;
        return -1;
    }
    /* No input for now */
    return 0;
}

/* _open: Open a file */
__attribute__((used))
int _open(const char *name, int flags, int mode) {
    errno = ENOSYS;
    return -1;
}

/* _close: Close a file */
__attribute__((used))
int _close(int file) {
    errno = ENOSYS;
    return -1;
}

/* _lseek: Seek to a position in a file */
__attribute__((used))
int _lseek(int file, int ptr, int dir) {
    errno = ENOSYS;
    return 0;
}

/* _fstat: Get file status */
__attribute__((used))
int _fstat(int file, struct stat *st) {
    st->st_mode = S_IFCHR;  /* Character device */
    return 0;
}

/* _isatty: Check if file is a terminal */
__attribute__((used))
int _isatty(int file) {
    return (file == STDIN_FILENO || file == STDOUT_FILENO || file == STDERR_FILENO);
}

/* _sbrk: Increase program data space
 * Uses zkvm-specific heap layout
 */
__attribute__((used))
void* _sbrk(uint32_t incr) {
    static char *heap_end = (char*)HEAP_START;
    char *prev_heap_end = heap_end;

    if (heap_end + incr > (char*)(HEAP_START + HEAP_SIZE)) {
        errno = ENOMEM;
        return (void*) -1;
    }

    heap_end += incr;
    return (void*) prev_heap_end;
}

/* _exit: Exit program
 * For zkvm, use shutdown ecall
 */
__attribute__((used))
void _exit(int code) {
    printf("exit code: %d\n", code);
    shutdown();
}

/* _kill: Send signal to a process */
__attribute__((used))
int _kill(int pid, int sig) {
    errno = ENOSYS;
    return -1;
}

/* _getpid: Get process ID */
__attribute__((used))
int _getpid(void) {
    return 1;  /* Always return PID 1 for bare metal */
}
