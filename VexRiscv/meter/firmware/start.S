.section .reset_vec
.globl _start
_start:
	la sp, _sp
	j start
	j .
/*ISR address*/
isr:
	lui t0, 0xC0000
	li t1, 1
	sb t1, 1(t0)
	sb zero, 1(t0)
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
	// enable interrupts
	csrsi mstatus, 8
	// enable timer interrupt
	li t1, 0x80
	csrw mie, t1

	call main
	j .
