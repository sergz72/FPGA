	jmp start
	reti
start:
	clr r0
	beq ok1
	hlt
ok1:
	ser r1
	inc r1
	beq ok2
	hlt
ok2:
	inc r0
	bne ok3
	hlt
ok3:
	cmp r0, $1
	beq ok4
	hlt
ok4:
	dec r0
	beq ok5
	hlt
ok5:
	wfi
	hlt
