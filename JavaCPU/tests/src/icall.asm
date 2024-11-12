	push ref
	icall 2
	ipush 1
	ifcmpeq next1
	hlt
next1:
	getsp
	ifeq ok
	hlt
ok:	wfi
p1:	ipush 1
	ret

.segment data
ref:	dd 0, 0
	dd p1
