	ipush 1
	ipush 2
	cmp
	ipush -1
	ifcmpeq next1
	hlt
next1:
	ipush 5
	ipush 4
	cmp
	ipush 1
	ifcmpeq next2
	hlt
next2:
	ipush 10
	ipush 10
	cmp
	ipush 0
	ifcmpeq next3
	hlt
next3:
	getsp
	ifeq ok
	hlt
ok:	wfi
