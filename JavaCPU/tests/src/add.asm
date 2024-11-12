	ipush 1
	ipush 2
	add
	ipush 3
	ifcmpeq next1
	hlt
next1:
	getsp
	ifeq ok
	hlt
ok:	wfi
