/* Startup code for RISC-V zkvm with newlib */

.section .text.init
.global _start

_start:
    /* Set up stack pointer */
    la sp, _init_stack_top

    /* Clear BSS section */
    la t0, _bss_start
    la t1, _bss_end
clear_bss:
    bgeu t0, t1, bss_done
    sb zero, 0(t0)
    addi t0, t0, 1
    j clear_bss
bss_done:

    /* Call main */
    call main

    /* Should never reach here, but just in case loop forever */
1:  j 1b
