	call p1
	getsp
	ifeq ok
	hlt
ok:	wfi
p1:	locals 2
	ipush 1
	setlocal 0
	ipush 2
	setlocal 1
	inc 0, 2
	inc 1, -3
	getlocal 0
	ipush 3
	ifcmpeq next1
	hlt
next1:
	getlocal 1
	ipush -1
	ifcmpeq next2
	hlt
next2:
	retn 2
