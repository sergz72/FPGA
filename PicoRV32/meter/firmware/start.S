.section .reset_vec
.globl _start
_start:
	call main
	j .
/*ISR address*/
isr:
	sret