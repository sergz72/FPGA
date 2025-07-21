#include "custom_ops.S"

.section .reset_vec
.globl _start, wfi, hlt, in, out

_start:
	j start
/*ISR address*/
	j isr1
	j isr2
	
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
