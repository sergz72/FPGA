#include "../../../custom_ops.S"

.section .reset_vec
.globl _start, wfi, hlt

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

start:
	la sp, _sp
	call main
	j .
