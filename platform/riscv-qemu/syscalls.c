/* Newlib syscall stubs for RISC-V bare metal on QEMU virt */

#include <sys/stat.h>
#include <sys/types.h>
#include <errno.h>
#include <unistd.h>
#include <stdint.h>

/* QEMU virt UART0 base address */
#define UART0_BASE 0x10000000
#define UART_TX    (*(volatile uint8_t*)(UART0_BASE + 0))
#define UART_LSR   (*(volatile uint8_t*)(UART0_BASE + 5))
#define UART_LSR_THRE (1 << 5)  /* Transmit holding register empty */

/* Simple UART output function */
static void uart_putc(char c) {
    /* Wait until transmit holding register is empty */
    while ((UART_LSR & UART_LSR_THRE) == 0);
    UART_TX = c;
}

/* Heap management */
extern char _heap_start[];
extern char _heap_end[];
static char *heap_ptr = NULL;

void *_sbrk(ptrdiff_t incr) {
    if (heap_ptr == NULL) {
        heap_ptr = _heap_start;
    }

    char *prev_heap_ptr = heap_ptr;

    if (heap_ptr + incr > _heap_end) {
        errno = ENOMEM;
        return (void *) -1;
    }

    heap_ptr += incr;
    return (void *) prev_heap_ptr;
}

/* _write: Write to a file
 * For now, we only support stdout/stderr to UART
 */
int _write(int file, char *ptr, int len) {
    int i;

    /* Only support stdout (1) and stderr (2) */
    if (file != STDOUT_FILENO && file != STDERR_FILENO) {
        errno = EBADF;
        return -1;
    }

    for (i = 0; i < len; i++) {
        if (ptr[i] == '\n') {
            uart_putc('\r');  /* Add carriage return for newline */
        }
        uart_putc(ptr[i]);
    }

    return len;
}

/* _read: Read from a file
 * Not implemented for this simple demo
 */
int _read(int file, char *ptr, int len) {
    errno = ENOSYS;
    return -1;
}

/* _close: Close a file */
int _close(int file) {
    errno = ENOSYS;
    return -1;
}

/* _lseek: Seek to a position in a file */
int _lseek(int file, int ptr, int dir) {
    errno = ENOSYS;
    return -1;
}

/* _fstat: Get file status */
int _fstat(int file, struct stat *st) {
    st->st_mode = S_IFCHR;  /* Character device */
    return 0;
}

/* _isatty: Check if file is a terminal */
int _isatty(int file) {
    return (file == STDIN_FILENO || file == STDOUT_FILENO || file == STDERR_FILENO);
}

/* _exit: Exit program
 * For QEMU, we can use the SiFive test device to exit
 */
#define SIFIVE_TEST_BASE 0x100000
#define SIFIVE_TEST_FINISHER (*(volatile uint32_t*)(SIFIVE_TEST_BASE))

void _exit(int status) {
    /* Print exit message */
    if (status == 0) {
        const char msg[] = "\nProgram exited successfully\n";
        _write(STDOUT_FILENO, (char*)msg, sizeof(msg) - 1);
    } else {
        const char msg[] = "\nProgram exited with error\n";
        _write(STDERR_FILENO, (char*)msg, sizeof(msg) - 1);
    }

    /* Signal QEMU to exit using the test device */
    /* Writing 0x5555 exits with success, 0x3333 with failure */
    SIFIVE_TEST_FINISHER = (status == 0) ? 0x5555 : 0x3333;

    /* Should never reach here, but just in case loop forever */
    while(1);
}

/* _kill: Send signal to a process */
int _kill(int pid, int sig) {
    errno = ENOSYS;
    return -1;
}

/* _getpid: Get process ID */
int _getpid(void) {
    return 1;  /* Always return PID 1 for bare metal */
}
