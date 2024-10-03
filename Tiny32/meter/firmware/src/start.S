#include "../../../custom_ops.S"

.section .reset_vec
.globl _start, wfi, getq
_start:
	j start
/*ISR address*/
isr:    retirq_insn()

wfi:
	waitirq_insn()
	ret

start:
	call main
	j .
