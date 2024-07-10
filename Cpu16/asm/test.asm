start:	nop
	jmp l1
	hlt
l1:	call l2
	jmp start
l2:	mov r0, 2
	jmp r0, l3
l3:	jmp p1
	jmp p2
	jmp p3
	jmp p4
	hlt
p1:	mov r1, 1
	out r0, r1, 1
	ret
p2:	mov r1, 2
	in  r0, r1, 1
	ret
p3:	ret
p4:	ret
