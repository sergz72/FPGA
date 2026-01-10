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
	mov r2, $AA55
	in r1, $55
	out $77, r2
	jal r0, test_f
	wfi
	hlt

test_f:
	lda r3, test_data
	lb r1, @r3
	rjmp r0

.segment bss
test_data: resb 1
