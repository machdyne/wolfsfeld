ENTRY(_start)

MEMORY
{
  FLASH (rx)  : ORIGIN = 0x80040000, LENGTH = 3840K
  RAM   (rwx) : ORIGIN = 0x40000000, LENGTH = 128K
}

SECTIONS
{
  /* Text section in flash */
  .text : {
    KEEP(*(.vectors))
    KEEP(*(.init))
    *(.text*)
    KEEP(*(.fini))
    _etext = .;
  } > FLASH

  /* Read-only data separate in flash */
  .rodata : {
    *(.rodata*)
    _erodata = .;
  } > FLASH

  /* Initialized data copy area in flash */
  .srodata : AT(_erodata) {
    _srodata_load = .;
    *(.srodata*)
    _esrodata_load = .;
  } > FLASH

  .sdata : AT(_esrodata_load) {
    _sdata_load = .;
    PROVIDE(__global_pointer$ = . + 0x800);
    *(.sdata*)
    _edata_load = .;
  } > FLASH

  .data : AT(_edata_load) {
    _data_load = .;
    *(.data*)
    _edata_load_end = .;
  } > FLASH

  /* RAM sections - VMA addresses */
  .rodata_ram (NOLOAD) : {
    _srodata = .;
    *(.srodata*)
    _esrodata = .;
  } > RAM

  .sdata_ram (NOLOAD) : {
    _sdata = .;
    *(.sdata*)
    _edata = .;
  } > RAM

  .data_ram (NOLOAD) : {
    _data = .;
    *(.data*)
    _edata_all = .;
  } > RAM

  .bss (NOLOAD) : {
    _bss = .;
    *(.bss*)
    *(COMMON)
    _ebss = .;
  } > RAM

  /* Stack at top of RAM */
  .stack (NOLOAD) : {
    . = ALIGN(8);
    _stack_top = ORIGIN(RAM) + LENGTH(RAM);
  } > RAM

  PROVIDE(_end = _ebss);
}
