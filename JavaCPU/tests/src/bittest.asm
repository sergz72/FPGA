	ipush $80
	ipush 7
	bittest
	ipush 1
	ifcmpeq next1
	hlt
next1:
	ipush $40
	ipush 7
	bittest
	ipush 0
	ifcmpeq next2
	hlt
next2:
	getsp
	ifeq ok
	hlt
ok:	wfi
