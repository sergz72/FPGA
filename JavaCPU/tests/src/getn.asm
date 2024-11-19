	push var
	ipush 1
	ipush 11
	getn 2
	ifcmpeq next1
	hlt
next1:
	drop2
	getsp
	ifeq ok
	hlt
ok:	wfi

.segment bss
var:	dw 11
