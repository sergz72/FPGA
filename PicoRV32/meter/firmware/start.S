#include "../../../custom_ops.S"

.section .reset_vec
.globl _start, wfi, getq
_start:
	picorv32_maskirq_insn(zero, zero)
	j start
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
	call main
	j .
