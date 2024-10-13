#include "custom_ops_tiny32.S"

.section .reset_vec
.globl _start, _wfi, hlt

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
