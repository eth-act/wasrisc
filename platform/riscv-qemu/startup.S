/* Startup code for RISC-V bare metal with newlib */

.section .text.init
.global _start
.global exit

_start:
    /* Set up stack pointer */
    la sp, _stack_top

    /* Set up global pointer (required for efficient access to globals) */
    .option push
    .option norelax
    la gp, __global_pointer$
    .option pop

    /* Clear BSS section */
    la t0, _bss_start
    la t1, _bss_end
clear_bss:
    bgeu t0, t1, bss_done
    sd zero, 0(t0)
    addi t0, t0, 8
    j clear_bss
bss_done:

    /* Call main */
    call main

exit:
    # https://github.com/xypron/riscv_test_payload (MIT-licensed)
    li a7, 0x53525354   # SBI extension: SRST (System Reset)
    li a6, 0            # Function: system reset
    li a0, 0            # Reset type: shutdown
    li a1, 0            # Reset reason: no reason
    ecall               # Perform system shutdown

    /* Should never reach here, but just in case loop forever */
1:  j 1b
