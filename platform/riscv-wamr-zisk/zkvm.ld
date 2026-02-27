OUTPUT_FORMAT("elf64-littleriscv")
OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY {
  rom   (xa) : ORIGIN = 0x80000000, LENGTH = 0x10000000
  ram   (wxa) : ORIGIN = 0xa0020000, LENGTH = 0x1FFE0000
}

PHDRS {
  text PT_LOAD FLAGS(5);
  rodata PT_LOAD FLAGS(4);
  data PT_LOAD FLAGS(6);
  bss PT_LOAD FLAGS(6);
}

SECTIONS
{
  .text : { *(.text.init) *(.text .text.*) *(.gnu.linkonce.t.*) } >rom AT>rom :text

  . = ALIGN(8);
  PROVIDE(_global_pointer = .);
  .rodata : { *(.rodata .rodata.* .srodata .srodata.*) *(.gnu.linkonce.r.*)} >rom AT>rom :rodata

  .data : { *(.data .data.* .sdata .sdata.* .gnu.linkonce.d.*) } >ram AT>ram :data

  .bss : {
    PROVIDE(_bss_start = .);
    *(.bss .bss.* .sbss .sbss.* .gnu.linkonce.b.* COMMON);
    PROVIDE(_bss_end = .);
  } >ram AT>ram :bss

  . = ALIGN(8);
  PROVIDE(_stack_top = . + 0x8000000);

  PROVIDE(_heap_start = _stack_top);
  PROVIDE(_heap_end = ORIGIN(ram) + LENGTH(ram));

  _end = .;
}
