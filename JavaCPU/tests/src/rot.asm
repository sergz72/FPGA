	ipush 1
	ipush 2
	ipush 3
        rot
        ipush 1
	ifcmpeq next1
	hlt
next1:
        ipush 3
	ifcmpeq next2
	hlt
next2:
        ipush 2
	ifcmpeq next3
	hlt
next3:
	getsp
	ifeq ok
	hlt
ok:	wfi
