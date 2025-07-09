.equ RAM_SIZE 4096

start:	jmp l1
	reti
.constants
l1:     mov r5, RAM_SIZE
        loadsp  r5
	mov r10, $5555
	mov r11, $AAAA
	mov r12, $1234
	call div3216
	mov r0, $6027
	cmp r10, r0
	beq ok1
	hlt
ok1:
	mov r0, 9
	cmp r11, r0
	beq ok2
	hlt
ok2:
	mov r0, $F69
	cmp r13, r0
	beq ok3
	hlt
ok3:
	wfi
