#include "../../custom_ops.S"

DELAY = 100000
LED_ADDRESS = 0xF8000000
UART_DATA_ADDRESS = 0xF0000000

.section .reset_vec
.globl _start

_start:
    j start

isr:
    lw t3, 0(t2)
test:
    lw t4, 0(t2)
    andi t4, t4, 0x100
    beqz t4, out_char
    j test
out_char:
    sb t3, 0(t2)
    retirq_insn()

start:
    lui t0, LED_ADDRESS >> 12
    lui t1, 0
    lui t2, UART_DATA_ADDRESS >> 12
loop:
    li t5, DELAY
delay_loop:
    addi t5, t5, -1
    bnez t5, delay_loop
    sw t1, 0(t0)
    addi t1, t1, 1
    j loop
