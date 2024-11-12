	ipush $FF000000
	ipush $00FF0000
	or
	ipush $FFFF0000
	ifcmpeq next1
	hlt
next1:
	getsp
	ifeq ok
	hlt
ok:	wfi
