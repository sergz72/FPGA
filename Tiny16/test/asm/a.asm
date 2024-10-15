	j start
	reti
start:
	lui SP, $FF80 >> 6
	jal SP, init
next:
	wfi
	inc A
	sw A, 0(X)
	j next

init:
	lui X, $8000 >> 6
	lui A, 0
	loadpc -1(SP)
