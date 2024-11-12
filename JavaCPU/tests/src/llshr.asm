	lpush -1
	ipush 2
	llshr
	lpush $3FFFFFFFFFFFFFFF
	ifcmpeq next1
	hlt
next1:
	getsp
	ifeq ok
	hlt
ok:	wfi
