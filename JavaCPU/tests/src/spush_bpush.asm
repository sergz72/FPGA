	spush 1
	spush -1
	spush 2
	add
	ifcmpeq next1
	hlt
next1:
	bpush 1
	bpush -1
	bpush 2
	add
	ifcmpeq next2
	hlt
next2:
	getsp
	ifeq ok
	hlt
ok:	wfi
