#include "custom_ops.S"

.section .reset_vec
.globl _start, wfi, hlt, in, out

_start:
	j start
/*ISR address*/
isr:
	retirq_insn()

wfi:
	waitirq_insn()
	ret

hlt:
	halt_insn()

in:
	in_insn(10, 10)
	ret

out:
	out_insn(10, 11)
	ret

start:
	la sp, _sp
	j main
