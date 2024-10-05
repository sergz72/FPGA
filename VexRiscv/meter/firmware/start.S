.section .reset_vec
.globl _start
_start:
	la sp, _sp
	j start
	j .
/*ISR address*/
isr:
	mret

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
	csrsi mstatus, 8
	li t1, 0x800
	csrw mie, t1

set_priv:
    li x1, 3 << 11
    li x2, 1 << 11
    csrc mstatus, x1
    csrs mstatus, x2
    auipc x1, 0
    addi x1, x1, 20
    csrw mepc, x1

	call main
	j .
