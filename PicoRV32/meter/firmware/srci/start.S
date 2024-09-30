#include "../../../custom_ops.S"

.section .reset_vec
.globl _start, wfi, getq
_start:
        la t0, isr
        picorv32_setq_insn(q2, t0)
	call main
	j .
/*ISR address*/
isr:    picorv32_retirq_insn()

wfi:
	picorv32_waitirq_insn(zero)
	ret
getq:
	picorv32_getq_insn(a1, q1)
	ret

.section .data
.globl interrupt
interrupt:
.dword 0

