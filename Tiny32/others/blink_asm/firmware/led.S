#include "../../custom_ops.S"

DELAY = 100000
LED_ADDRESS = 0xF8000000
UART_DATA_ADDRESS = 0xF0000000
TIMER_ADDRESS = 0xE8000000
MAX_COMMAND_SIZE = 128

.section .reset_vec
.globl _start

_start:
    j start

    j isr_timer

isr_uart:
    lb t5, 0(t0)

    bnez t4, ret_isr // command_ready

    bgeu t2, t3, no_store
    sb t5, 0(t2)
    addi t2, t2, 1
no_store:
    li t6, 0x0D
    bne t5, t6, ret_isr
    mv t4, t6 //command_ready
ret_isr:    
    retirq_insn()

isr_timer:
    lui t1, 1 // timer_interrupt
    retirq_insn()

out_char:
    lw a6, 0(t0)
    andi a6, a6, 0x100
    beqz a6, out_char_
    j out_char
out_char_:
    sb a5, 0(t0)
    ret

start:
    lui t0, UART_DATA_ADDRESS >> 12
    mv  t1, zero // timer_interrupt
    la  t2, command_buffer
    mv  t3, t2
    mv  a3, t2
    mv  t4, zero //command_ready
    addi t3, t3, MAX_COMMAND_SIZE
    li a0, DELAY
    lui a1, LED_ADDRESS >> 12
    lui a2, TIMER_ADDRESS >> 12
    lui a4, 0

loop:
    sw a0, 0(a2)
wfi_:
    waitirq_insn()
    beqz t1, wfi_
    mv t1, zero

uart_handler:
    beq a3, t2, check_command_ready
    lb a5, 0(a3)
    addi a3, a3, 1
    jal out_char
    j uart_handler

check_command_ready:
    beqz t4, led_handler // command_ready
    la  t2, command_buffer
    mv a3, t2
    mv t4, zero

led_handler:
    sw a4, 0(a1)
    addi a4, a4, 1
    j loop

.section .bss

command_buffer:
    .skip MAX_COMMAND_SIZE+1
