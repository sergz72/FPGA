	ipush 1
	ipush 2
        drop
        ipush 1
	ifcmpeq next1
	hlt
next1:
	getsp
	ifeq ok
	hlt
ok:	wfi
