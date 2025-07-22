#include "../../../custom_ops.S"

.globl ST7789_WriteBytes,ST7789_WriteColor

// a0 = flags
// a1 = address
// a2 = size
// t0,t1 - work registers
ST7789_WriteBytes:
    lui  t0, 0x40000
    add  a2, a1, a2
ST7789_WriteBytes_loop:
    // in to t1
    in_insn(6, 0)
    andi t1, t1, 4
    bnez t1, ST7789_WriteBytes_loop
    lbu  t1, 0(a1)
    addi a1, a1, 1
    or   t1, t1, a0
    // out t1 to [t0]
    out_insn(6, 5)
    bne  a1,a2, ST7789_WriteBytes_loop
    ret

// a0 = color
// a1 = count
// t0, t1, t2 - work registers
ST7789_WriteColor:
    srli t1, a0, 8
    ori  t1, t1, 0x100
    andi a0, a0, 0xFF
    ori  a0, a0, 0x100
    lui  t0, 0x40000
ST7789_WriteColor_loop:
    // in to t2
    in_insn(7, 0)
    andi t2, t2, 4
    bnez t2, ST7789_WriteColor_loop
    // out a0 to [t0]
    out_insn(10, 5)
ST7789_WriteColor_loop2:
    // in to t2
    in_insn(7, 0)
    andi t2, t2, 4
    bnez t2, ST7789_WriteColor_loop2
    // out t1 to [t0]
    out_insn(6, 5)
    addi a1, a1, -1
    bnez a1, ST7789_WriteColor_loop
    ret
