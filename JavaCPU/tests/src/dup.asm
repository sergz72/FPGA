	ipush 1
	ipush 2
        dup
        ipush 2
	ifcmpeq next1
	hlt
next1:
	ipush 2
	ifcmpeq next2
	hlt
next2:
	ipush 1
	ifcmpeq next3
	hlt
next3:
	getsp
	ifeq ok
	hlt
ok:	wfi
