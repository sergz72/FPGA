	jmp start
	reti
start:
; mov
	mov r0, $55AA
	cmp r0, $55AA
	bne hlt1
	mov r0, $7F
	cmp r0, $7F
	bne hlt1
	mov r1, r0
	cmp r1, $7F
	bne hlt1
; clr
	ser r0
	beq hlt1
	clr r0
	beq ok1
hlt1:
	hlt
ok1:
; ser
	ser r1
	inc r1
	bne hlt1
; inc
	inc r0
	beq hlt1
	cmp r0, $1
	bne hlt1
; dec
	dec r0
	bne hlt1
	inc r0
; ror
	ror r0
	bne hlt1
	bcc hlt1
	ror r0
	bcs hlt1
	bpl hlt1
	cmp r0, $8000
	bne hlt1
; rol
	rol r0
	bne hlt1
	bcc hlt1
	rol r0
	bcs hlt1
	cmp r0, 1
	bne hlt1
; not
	not r0
	cmp r0, $FFFE
	bne hlt1
; neg
	neg r0
	cmp r0, 2
	bne hlt1
; shr
	shr r0
	cmp r0, 1
	bne hlt1
	shr r0
	bcc hlt1
	bne hlt1
; shl
	mov r0, $4000
	shl r0
	cmp r0, $8000
	bne hlt1
	shl r0
	bcc hlt1
	bne hlt1
; test
	ror r0
	test r0, $8000
	beq hlt1
	mov r0, 2
	test r0, $1
	bne hlt1
	cmp r0, 2
	bne hlt1
;clc/stc
	stc
	bcc hlt2
	clc
	bcs hlt2
	stc
	bcs ok2
hlt2:
	hlt
ok2:
; add
	add r0, 2
	cmp r0, 4
	bne hlt2
	add r0, $FFFC
	bne hlt2
	bcc hlt2
	mov r1, $55
	mov r0, $AA00
	add r0, r1
	cmp r0, $AA55
	bne hlt2
; sub
	sub r0, $AA56
	bcc hlt2
	bpl hlt2
	cmp r0, $FFFF
	bne hlt2
	sub r0, 1
	cmp r0, $FFFE
	bne hlt2
	sub r0, r1
	cmp r0, $FFFE-$55
	bne hlt2

	mov r2, $AA55
	swab r2
	cmp r2, $55AA
	bne hlt2
; io
	in r1, $55
	out $77, r2
	jal r0, test_f
	wfi
	hlt

test_f:
	clc
	stc
	lda r3, test_data
	sb @r3, r2
	lb r1, @r3
	cmp r1, $FFAA
	bne hlt3
	lbu r1, @r3
	cmp r1, $AA
	bne hlt3
	add r3, 2
	sw @r3, r2
	lw r4, @r3
	cmp r4, r2
	bne hlt3
	rjmp r0
hlt3:	
	hlt

.segment bss
test_data: resb 1
