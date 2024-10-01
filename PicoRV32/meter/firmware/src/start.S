#include "../../../custom_ops.S"

.section .reset_vec
.globl _start, wfi, getq
_start:
	picorv32_maskirq_insn(zero, zero)
	call main
	j .
	j .
/*ISR address*/
isr:    picorv32_retirq_insn()

wfi:
	picorv32_waitirq_insn(zero)
	ret
getq:
	picorv32_getq_insn(a1, q1)
	ret
