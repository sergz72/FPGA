TIMER_ADDRESS = 0x40000000

.section .reset_vec
.globl _start, delay
_start:
	la sp, _sp
	j start
	j .
/*ISR address*/
isr:
	addi sp, sp, -8
	sw t0, 0(sp)
	sw t1, 4(sp)
        lui t0, 0x30000
        li t1, 1
        sb t1, 1(t0)
        sb zero, 1(t0)
	lw t0, 0(sp)
	lw t1, 4(sp)
	addi sp, sp, 8
        mret

delay:
	lui t0, TIMER_ADDRESS >> 12
	sw a0, 0(t0)
	wfi
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
