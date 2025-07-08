.equ RAM_SIZE 4096

	jmp start
	reti
.constants
start:
	mov r5, RAM_SIZE
	loadsp  r5
	mov r4, r5
	xor r5, r5
	beq next0
	hlt
next0:
	mov r3, RAM_SIZE
	cmp r4, r3
	beq next1
	hlt
next1:
	bpl next2
	hlt
next2:	
	dec r5
	bc  next3
	hlt
next3:
	bmi next4
	hlt
next4:
	bne next5
	hlt
next5:
	inc r5
	beq next6
	hlt
next6:
	bc  next7
	hlt
next7:
	inc r5
	bnc next8
	hlt
next8:
	push r5
	pop r1
	cmp r5, r1
	beq next9
	hlt
next9:
	test r5, r1
	bne next10
	hlt
next10:
	inc r1	
	test r5, r1
	beq next11
	hlt
next11:
	call next_tests
	clr r5
loop:
	out r0, r5
	wfi
	xor r5, 1
	jmp loop

next_tests:
	add r5, r1 ; 3
	lda r1, variable1
	mov @r1, r5
	clr r5
	mov r5, @r1
	cmp r5, 3
	beq next12
	hlt
next12:
	sub r5, 4
	bc next13
	hlt
next13:
	mov r2, 2
	and r5, r2
	cmp r5, 2
	beq next14
	hlt
next14:
	xor r5, r2
	beq next15
	hlt
next15:
	or r5, 3
	cmp r5, 3
	beq next16
	hlt
next16:
	shl r1, r5
	cmp r1, 6
	beq next17
	hlt
next17:
	cmp r5, 3
	beq next18
	hlt
next18:
	shr r1, r1
	shr r1, r1
	rol r5, r5
	cmp r1, 1
	beq next19
	hlt
next19:
	cmp r5, 7
	beq next20
	hlt
next20:	
	ror r4, r5
	bc next21
	hlt
next21:
	cmp r4, 3
	beq next22
	hlt
next22:
	ser r8
	cmp r8, -1
	beq next23
	hlt
next23:
	add r8, 1
	adc r4, 0
	cmp r4, 4
	beq next24
	hlt
next24:
	sub r8, 1
	sbc r4, 0			
	cmp r4, 3
	beq next25
	hlt
next25:
	in r5, r0
	mov r9, $55AA
	cmp r5, r9
	beq next26
	hlt
next26:
	ret

.segment bss
variable1: resw 1
