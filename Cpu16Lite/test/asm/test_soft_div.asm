start:	jmp l1
	reti
l1:	mov r17, $AAAA
	mov r16, $5555
	mov r18, $1234
	call div3216
	; 0x6027
	out [r1], r16
	; 0x0009
	out [r1], r17
	; 0x0F69
	out [r1], r19
	jmp start
