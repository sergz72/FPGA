	jmp start
	reti
start:  loada r1, l3
	jmp r1+2
l4:	call l1
	jmp start
l1:	call l2
	ret
l2:	ret
l3:	nop
	nop
	loada r1, l5
	call r1
	jmp l4
l5:	mov rp, 203
	mov @rp, 1
	mov @--rp, 2
	mov @--rp, 3
	mov @--rp, 4
	mov r2, 100
	out [r2], r2
	out [r2], @rp
	out [r2], @rp++
	out [r2], @rp++
	out [r2], @rp++
	out [r2], @rp++
	out [r2], @--rp
	out [r2], @--rp
	ret
