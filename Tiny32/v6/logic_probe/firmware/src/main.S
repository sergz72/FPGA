#include "../../../custom_ops.S"

.globl ST7789_WriteBytes,ST7789_WriteColor

// a0 = flags
// a1 = address
// a2 = size
// a3,a4 - work registers
ST7789_WriteBytes:
    lui  a3, 0x40000
    add  a2, a1, a2
ST7789_WriteBytes_loop:
    lbu  a4, 0(a1)
    addi a1, a1, 1
    or   a4, a4, a0
    out_insn(14, 13)
    bne  a1,a2, ST7789_WriteBytes_loop
    ret

// a0 = color
// a1 = count
// a2,a3,a4 - work registers
ST7789_WriteColor:
    srli a3, a0, 8
    ori  a3, a3, 0x100
    andi a0, a0, 0xFF
    ori  a0, a0, 0x100
    lui  a2, 0x40000
ST7789_WriteColor_loop:
    in_insn(14, 0)
    andi a4, a4, 4
    bnez a4, ST7789_WriteColor_loop
    out_insn(10, 12)
ST7789_WriteColor_loop2:
    in_insn(14, 0)
    andi a4, a4, 4
    bnez a4, ST7789_WriteColor_loop2
    out_insn(13, 12)
    addi a1, a1, -1
    bnez a1, ST7789_WriteColor_loop
    ret
