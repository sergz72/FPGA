start:	jmp l1
	reti
l1:	mov r1, $5555
	mov r0, $AAAA
	mul r2, r1, r0
	mov r3, alu_out_2
	out [r1], r2
	out [r1], r3
;	div r0, r2, r3 ; r0 = r2:r3/r0
	mov r17, 0
	mov r16, 10005
	out [r1], r16
	mov r18, 10
	call div3216
	out [r1], r16
	out [r1], r17
	out [r1], r19
	jmp start
