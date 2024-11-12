	ipush 1
	ipush 2
	shl
	ipush 4
	ifcmpeq next1
	hlt
next1:
	getsp
	ifeq ok
	hlt
ok:	wfi
