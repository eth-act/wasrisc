.section .text.init
.global _start

_start:
    la sp, _stack_top

    /* Clear BSS section - using symbols defined in our linker script */
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

    /* https://github.com/xypron/riscv_test_payload (MIT-licensed) */
    li a7, 0x53525354   # SBI extension: SRST (System Reset)
    li a6, 0            # Function: system reset
    li a0, 0            # Reset type: shutdown
    li a1, 0            # Reset reason: no reason
    ecall               # Perform system shutdown
end:
    j end
