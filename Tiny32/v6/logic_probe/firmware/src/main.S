#include "../../../custom_ops.S"

.globl ST7789_WriteBytes
// a0 = flags
// a1 = address
// a2 = size
ST7789_WriteBytes:
    mv   a4, a1
    mv   a5, a0
    lui  a1, 0x40000
ST7789_WriteBytes_loop:
    lbu  a0, 0(a4)
    addi a4, a4, 1
    or   a0, a0, a5
    out_insn(10, 11)
    addi a2,a2,-1
    bnez a2, ST7789_WriteBytes_loop
    ret
