#include "../../../custom_ops.S"

.section .reset_vec
.globl _start, wfi

_start:
	j start
/*ISR address*/
isr:
	sw a0, -4(sp)
	sw a1, -8(sp)
	lui a1, 0xC0000
	addi a0, zero, 1
	sb a0, 1(a1)
	sb zero, 1(a1)
	lw a1, -8(sp)
	lw a0, -4(sp)
	retirq_insn()

wfi:
	waitirq_insn()
	ret

start:
	la sp, _sp
	call main
	j .
