	ipush $55555555
	ipush $FFFFFFFF
	xor
	ipush $AAAAAAAA
	ifcmpeq next1
	hlt
next1:
	getsp
	ifeq ok
	hlt
ok:	wfi
