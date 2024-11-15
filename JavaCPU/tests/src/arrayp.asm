	push ref
	ipush 5
	arrayp
	iget
	ipush 10
	ifcmpeq next1
	hlt
next1:
	push ref2
	ipush 2
	arrayp2
	lget
	lpush $1100000010
	ifcmpeq next2
	hlt
next2:
	ipush 15
	push ref
	ipush 5
	arrayp
	iset

	ipush 5
	push ref2
	ipush 2
	arrayp2
	lset

	push ref
	ipush 5
	arrayp
	iget
	ipush 15
	ifcmpeq next3
	hlt
next3:
	push ref2
	ipush 2
	arrayp2
	lget
	ipush 5
	ifcmpeq next4
	hlt
next4:
	getsp
	ifeq ok
	hlt
ok:	wfi
p1:	ipush 1
	ret

.segment data
ref:	dd 0, 0, 0, 0, 0, 0, 10
ref2:	dd 0, 0, 0, 0, 0, $10, $11
