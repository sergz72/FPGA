#include "../../../custom_ops.S"

.section .reset_vec
.globl _start

_start:
	j start
/*ISR address*/
isr:
	retirq_insn()
in:
	in_insn(10, 10)
	ret
out:
	out_insn(10, 11)
	ret
wfi:
	waitirq_insn()
	ret
hlt:
	halt_insn()

start:
	la sp, _sp
	j main
main:
	lui a0,0xc0000
	jal in
	li  a5, 0x12345678
	bne a0, a5, halt
	lui s0, 0x80000
	xor a0, a0, a0
next:
	jal wfi
	lw  a0, 0(s0)
	lui a1, 0xc0000
	xori a0, a0, 1
	sw a0, 0(s0)
	jal out
	j next
halt:
	jal hlt
