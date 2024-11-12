	ipush 12345
	ipush 54321
	mul
	ipush 12345 * 54321
	ifcmpeq next1
	hlt
next1:
	getsp
	ifeq ok
	hlt
ok:	wfi
