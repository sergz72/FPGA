	ipush $FFFFFFFF
	ipush 2
	ashr
	ipush $FFFFFFFF
	ifcmpeq next1
	hlt
next1:
	ipush $7FFFFFFF
	ipush 2
	ashr
	ipush $1FFFFFFF
	ifcmpeq next1
	hlt
next1:
	getsp
	ifeq ok
	hlt
ok:	wfi
