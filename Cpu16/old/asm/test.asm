start:	jmp l1
interrupt_vector:
	mov r255, $55AA
	out r0, r255
	reti
l1:	call l2
	jmp start
l2:	mov r0, 1
	ser r2
	dec r2
	dec r2
	jmpz r0, l3
l3:	jmp p1
	jmp p2
	jmp p3
	jmp p4
	hlt
p1:	mov r1, r2 + 1
	out r2, r1 + 1
	ret
p2:	mov r1, 2
	in  r0, r1 + 1
	ret
p3:	ret
p4:	test r0, $FFFF
	test r0, r2
	test r0, [r2]
	cmp  r1, $5555
	cmp  r1, r2
	cmp  r3, [r4]
	add  r0, r1, r2
	add  r0, r1, [r2]
	add  [r0], r1, r2
	add  r1, r2
	add  r0, 3
	ret
