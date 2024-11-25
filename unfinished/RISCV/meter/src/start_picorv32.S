#include "custom_ops_picorv32.S"

TIMER_ADDRESS = 0xE0000000
TIME_ADDRESS = 0xD8000000

.section .reset_vec
.globl _start, _wfi, getq, delay, delay_start, gettime
_start:
	picorv32_maskirq_insn(zero, zero)
	j start
	j .
	j .

/*ISR address*/
isr:
  picorv32_retirq_insn()

_wfi:
	picorv32_waitirq_insn(zero)
	ret
getq:
	picorv32_getq_insn(a1, q1)
	ret

delay_start:
  lui t0, TIMER_ADDRESS >> 12
  sw a0, 0(t0)
  ret

delay:
  lui t0, TIMER_ADDRESS >> 12
  sw a0, 0(t0)
  picorv32_waitirq_insn(zero)
  ret

gettime:
  lui t0, TIME_ADDRESS >> 12
  lw a0, 0(t0)
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
