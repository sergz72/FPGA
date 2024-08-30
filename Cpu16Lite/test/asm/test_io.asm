start:	jmp l1
	reti
l1:	clr r0
	mov r1, $200
	; ram
	out [r0], r1
	in r2, [r0]
	add r0, $200
	; rom
	out [r0], r2
	add r0, $200
	; scl, sda
	out [r0], r1
	inc r1
	out [r0], r1
	inc r1
	out [r0], r1
	inc r1
	out [r0], r1
	in r2, [r0]
	add r0, $200
	; ks_data
	out [r0], r2
	add r0, $200
	in r2, [r0]
	add r0, $200
	in r2, [r0]
	jmp l1
