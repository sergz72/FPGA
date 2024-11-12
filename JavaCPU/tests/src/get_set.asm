	push var
	ipush 1
	over
	iset
	iget
	ipush 1
	ifcmpeq next1
	hlt
next1:
	push var
	lpush $FFFFFFFFFFFF
	over
	lset
	lget
	lpush $FFFFFFFFFFFF
	ifcmpeq next2
	hlt
next2:
	getsp
	ifeq ok
	hlt
ok:	wfi

.segment bss
var:	resw 2
