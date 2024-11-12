	ipush $FFFF0000
	ipush $00FF0000
	and
	ipush $FF0000
	ifcmpeq next1
	hlt
next1:
	getsp
	ifeq ok
	hlt
ok:	wfi
