/* Linker script for QEMU RISC-V virt machine */

OUTPUT_FORMAT("elf64-littleriscv")
OUTPUT_ARCH("riscv")
ENTRY(_start)

/* QEMU virt machine memory map */
MEMORY {
    ram (wxa) : ORIGIN = 0x80200000, LENGTH = 2048M
}

SECTIONS
{
    /* Start of RAM */
    . = 0x80200000;

    /* Code section */
    .text : {
        KEEP(*(.text.init))  /* Keep startup code first */
        *(.text .text.*)
        *(.gnu.linkonce.t.*)
    } >ram

    /* Align to 8 bytes */
    . = ALIGN(8);

    /* Global pointer for efficient access to small data */
    PROVIDE(__global_pointer$ = . + 0x800);

    /* Read-only data */
    .rodata : {
        *(.rodata .rodata.*)
        *(.gnu.linkonce.r.*)
    } >ram

    /* Align to 8 bytes */
    . = ALIGN(8);

    /* Initialized data */
    .data : {
        *(.data .data.*)
        *(.sdata .sdata.*)
        *(.gnu.linkonce.d.*)
    } >ram

    /* Align to 8 bytes */
    . = ALIGN(8);

    /* Uninitialized data (BSS) */
    .bss : {
        PROVIDE(_bss_start = .);
        *(.bss .bss.*)
        *(.sbss .sbss.*)
        *(.gnu.linkonce.b.*)
        *(COMMON)
        PROVIDE(_bss_end = .);
    } >ram

    /* Align to page boundary */
    . = ALIGN(0x1000);

    /* Heap for malloc */
    PROVIDE(_heap_start = .);
    . = . + 1024M;
    PROVIDE(_heap_end = .);

    /* Stack grows downward from top of RAM */
    . = . + 128M;  /* 128MB stack */
    PROVIDE(_stack_top = .);

    /* End marker */
    PROVIDE(_end = .);
}
