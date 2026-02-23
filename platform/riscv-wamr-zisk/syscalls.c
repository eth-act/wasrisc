#include <errno.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>

void writeuartcc(const char c) {
    char *ptr_val = (char *)(0xa0000000+512);
    *ptr_val = c;
}

int readuartcc() {
    while(1) { };
    return -1;
}

/* shutdown: Signal zkvm to exit via ecall 93 */
void shutdown() {
    __asm__ volatile("li a7, 93");
    __asm__ volatile("ecall");
}

// ---

int _write(int file, char *ptr, int len) {
    // We're only handling stdout and stderr
    if (file != STDOUT_FILENO && file != STDERR_FILENO) {
        errno = EBADF;
        return -1;
    }

    int i;
    for (i = 0; i < len; i++) {
        writeuartcc(ptr[i]);
    }
    return len;
}

int _read(int file, char *ptr, int len) {
    // We're only handling stdin
    if (file != STDIN_FILENO) {
        errno = EBADF;
        return -1;
    }

    int i;
    for (i = 0; i < len; i++) {
        ptr[i] = readuartcc();
        if (ptr[i] == '\r' || ptr[i] == '\n') {
            i++;
            break;
        }
    }
    return i;
}

// Other required syscalls with minimal implementations
int _open(const char *name, int flags, int mode) { errno = ENOSYS; return -1; }
int _close(int file) { return -1; }
int _lseek(int file, int ptr, int dir) { return 0; }
int _fstat(int file, struct stat *st) {
    st->st_mode = S_IFCHR;
    return 0;
}
int _isatty(int file) {
    return 1;
}

void* _sbrk(int incr) {
    extern char _heap_start;   // Defined by the linker - start of heap
    extern char _heap_end;     // Defined by the linker - end of heap

    static char *current = &_heap_start;
    char *prev = current;

    // Check if heap would grow too close to stack
    if ((current + incr > &_heap_end) || (current + incr < current)) {
        errno = ENOMEM;
        return (void*) -1; // Return error
    }

    current += incr;
    return (void*) prev;
}

// Required stubs
void _exit(int code) {
    shutdown();
    while (1) {}
}
int _kill(int pid, int sig) { return -1; }
int _getpid(void) { return 1; }
