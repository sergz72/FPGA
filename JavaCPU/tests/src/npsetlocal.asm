	call p1
	getsp
	ifeq ok
	hlt
ok:	wfi
p1:	locals 2
	ipush 1
	setlocal 0
	ipush 2
	npsetlocal 1
	getlocal 0
	add
	getlocal 1
	mul
	bpush 6
	ifcmpeq next1
	hlt
next1:
	retn 2
