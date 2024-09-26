start:	jmp l1
	reti
l1:	clr r1
	mov r16, $5555
	mov r17, $AAAA
	out [r1], r16
	out [r1], r17
	call mul1616
	out [r1], r18
	out [r1], r19
	jmp start
