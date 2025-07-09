.equ RAM_SIZE 4096

start:	jmp l1
	reti
.constants
l1:     mov r5, RAM_SIZE
        loadsp  r5
	mov r11, $5555
	mov r12, $AAAA
	call mul1616
	mov r0, $1C72
	cmp r13, r0
	beq ok1
	hlt
ok1:
	mov r0, $38E3
	cmp r14, r0
	beq ok2
	hlt
ok2:
	wfi
