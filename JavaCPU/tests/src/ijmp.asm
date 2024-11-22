	bpush 3
	ijmp
	jmp l1
	jmp l2
	jmp l3
	jmp l4
l1: hlt
l2: hlt
l3: hlt
l4:
	getsp
	ifeq ok
	hlt
ok:	wfi
