	ipush 12345 * 54321
	ipush 54321
	div
	ipush 12345
	ifcmpeq next1
	hlt
next1:
	getsp
	ifeq ok
	hlt
ok:	wfi
