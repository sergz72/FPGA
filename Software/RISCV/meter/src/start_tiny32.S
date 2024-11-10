#include "custom_ops_tiny32.S"

TIMER_ADDRESS = 0xE0000000
TIME_ADDRESS = 0xD8000000

.section .reset_vec
.globl _start, _wfi, hlt, delay, delay_start, gettime

_start:
	j start
/*ISR address*/
isr:
	retirq_insn()

_wfi:
	waitirq_insn()
	ret

hlt:
	halt_insn()

delay_start:
	lui t0, TIMER_ADDRESS >> 12
	sw a0, 0(t0)
	ret

delay:
	lui t0, TIMER_ADDRESS >> 12
	sw a0, 0(t0)
	waitirq_insn()
	ret

gettime:
	lui t0, TIME_ADDRESS >> 12
	lw a0, 0(t0)
	ret

start:
        // clearing bss...
        la a0, _bss_start
        la a1, _bss_end
next:
        beq a0, a1, done
        sw zero, 0(a0)
        addi a0, a0, 4
        j next
done:
	la sp, _sp
	call main
	j .
