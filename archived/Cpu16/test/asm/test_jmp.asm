start:	jmp l1
	reti
l1:	clr r0
	test r0, r0
	jmpnz error
	jmpz  next1
	hlt
next1:	inc r0
	jmpz error
	jmpnz next2
	hlt
next2:	sub r0, 2
	jmpnc error
	jmpc next3
	hlt
next3:	sub r0, 2
	jmpc error
	jmpnc next4
	hlt
next4:	mov r0, 2
	cmp r0, 1
	jmple error
	jmpgt next5
	hlt
next5:	cmp r0, 2
	jmpgt error
	jmple start
error:	hlt
