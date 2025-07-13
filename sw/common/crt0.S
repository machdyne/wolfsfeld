.section .vectors, "a", @progbits
.globl _start
_start:
    j reset

.section .text
.globl reset
reset:
    la sp, _stack_top
    la gp, __global_pointer$

    /* Copy .srodata from flash to RAM */
    la a0, _srodata
    la a1, _esrodata
    la a2, _srodata_load
    call memcpy_section

    /* Copy .sdata from flash to RAM */
    la a0, _sdata
    la a1, _edata
    la a2, _sdata_load
    call memcpy_section

    /* Copy .data from flash to RAM */
    la a0, _data
    la a1, _edata_all
    la a2, _data_load
    call memcpy_section

    /* Zero .sbss */
    la a0, _sbss
    la a1, _esbss
    call zero_section

    /* Zero .bss */
    la a0, _bss
    la a1, _ebss
    call zero_section

    call main

1:  j 1b

.type memcpy_section, @function
memcpy_section:
    beq a0, a1, .Lcopy_done
.Lcopy_loop:
    lw t0, 0(a2)
    sw t0, 0(a0)
    addi a0, a0, 4
    addi a2, a2, 4
    blt a0, a1, .Lcopy_loop
.Lcopy_done:
    ret

.type zero_section, @function
zero_section:
    beq a0, a1, .Lzero_done
.Lzero_loop:
    sw zero, 0(a0)
    addi a0, a0, 4
    blt a0, a1, .Lzero_loop
.Lzero_done:
    ret

