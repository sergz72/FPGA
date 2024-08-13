start:	jmp l1
	reti
l1:	call l2
	jmp start
l2:	mov r0, 0
	inc r0
	mov r1, $5555
	dec r1
	neg r1, r1
	out [r1], r0
	in  r2, [r1]
	inc r2
	add r0, r0, r2
	out [r1], r0
	sub r0, 1
	out [r1], r0
	or  r0, $8000
	out [r1], r0
	and r0, $7FFF
	out [r1], r0
	xor r0, $5555
	out [r1], r0
	ret
