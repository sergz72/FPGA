	j start
	reti
start:
	lli SP, $FF80
	jal SP, init
next:
	wfi
	xor A, W
	sw A, 0(X)
	j next

init:
	li X, $8000
	lli A, 0
	lli W, 1
	loadpc -1(SP)
