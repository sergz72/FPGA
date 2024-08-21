start:	jmp l1
	reti
l1:	mov r17, 0
	mov r16, 10005
	out [r1], r16
	mov r18, 10
	call div3216
	out [r1], r16
	out [r1], r17
	out [r1], r19
	jmp start
