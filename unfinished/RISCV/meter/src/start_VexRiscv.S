TIMER_ADDRESS = 0xE0000000
TIME_ADDRESS = 0xD8000000

.section .reset_vec
.globl _start, _wfi, delay, delay_start, gettime
_start:
	la sp, _sp
	j start
	j .
/*ISR address*/
isr:
	lui t0, 0xF8000
	li t1, 1
	sb t1, 1(t0)
	sb zero, 1(t0)
	mret

_wfi:
	wfi
	ret

delay_start:
	lui t0, TIMER_ADDRESS >> 12
	sw a0, 0(t0)
	ret

delay:
	lui t0, TIMER_ADDRESS >> 12
	sw a0, 0(t0)
	wfi
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
	// enable timer and external interrupts
	li t1, 0x880 
	csrw mie, t1
	// enable interrupts
	li t1, 0x1808
	csrw mstatus, t1

	call main
	j .
