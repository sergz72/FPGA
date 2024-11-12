	ipush $FFFFFFFF
	ipush 2
	ilshr
	ipush $3FFFFFFF
	ifcmpeq next1
	hlt
next1:
	getsp
	ifeq ok
	hlt
ok:	wfi
