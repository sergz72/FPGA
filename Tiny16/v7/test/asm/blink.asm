	jmp start
	reti
start:
	clr r0
loop:
	out 0, r0
	inc r0
	wfi
	br loop
