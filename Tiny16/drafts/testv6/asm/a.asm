.equ RAM_SIZE 4096
.equ SP RAM_SIZE-128

	jmp start
	reti
.constants
start:
	mov r0, SP
	loadsp  r0
	xor r0, r0
	beq next1
	hlt
next1:
	bpl next2
	hlt
next2:	
	dec r0
	bc  next3
	hlt
next3:
	bmi next4
	hlt
next4:
	bne next5
	hlt
next5:
	inc r0
	beq next6
	hlt
next6:
	bc  next7
	hlt
next7:
	inc r0
	bnc next8
	hlt
next8:
	push r0
	pop r1
	cmp r0, r1
	beq next9
	hlt
next9:
	test r0, r1
	bne next10
	hlt
next10:
	inc r1	
	test r0, r1
	beq next11
	hlt
next11:
	call func				
	wfi

func:
	ret
