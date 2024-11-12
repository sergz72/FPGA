	call p1
	call p2
	ifcmpeq next1
	hlt
next1:
	getsp
	ifeq ok
	hlt
ok:	wfi
p1:	ipush 1
	ret
p2:	locals 2
	ipush 1
	retn 2
