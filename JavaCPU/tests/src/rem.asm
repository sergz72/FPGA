	ipush 10005
	ipush 10
	rem
	ipush 5
	ifcmpeq next1
	hlt
next1:
	getsp
	ifeq ok
	hlt
ok:	wfi
