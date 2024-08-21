start:	jmp l1
	mov r255, $FFFF
	out [r255], r255 ; clear interrupt flag
	reti
l1:	hlt
	call l2
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
	mov r1, $5555
	mov r0, $AAAA
	mul r2, r1, r0
	mov r3, alu_out_2
	out [r1], r2
	out [r1], r3
	div r0, r2, r3 ; r0 = r2:r3/r0
	mov r1, alu_out_2
	out [r1], r0
	out [r1], r1
	mov r1, $1
	mov r0, $86A5
	mov r2, 10
	rem r2, r0, r1; r2 = r1:r0 % r2
	out [r1], r2
	ret
