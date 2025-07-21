#include "../../../custom_ops.S"

.globl ST7789_WriteBytes
// a0 = flags
// a1 = address
// a2 = size
ST7789_WriteBytes:
    lui  a3, 0x40000
ST7789_WriteBytes_loop:
    lbu  a4, 0(a1)
    addi a1, a1, 1
    or   a4, a4, a0
    out_insn(14, 13)
    addi a2,a2,-1
    bnez a2, ST7789_WriteBytes_loop
    ret
