	lpush 1
	lpush 1
	ifcmpeq next1
	hlt
next1:
	lpush 1
	lpush 1
	ifcmpge next2
	hlt
next2:
	lpush 1
	lpush 1
	ifcmple next3
	hlt
next3:
        lpush 1
	lpush 2
	ifcmpne next4
	hlt
next4:
        lpush 1
	lpush 2
	ifcmplt next5
	hlt
next5:
        lpush 2
	lpush 1
	ifcmpgt next6
	hlt
next6:
	lpush 0
	ifeq next7
	hlt
next7:
	lpush 0
	ifge next8
	hlt
next8:
	lpush 0
	ifle next9
	hlt
next9:
	lpush 1
	ifne next10
	hlt
next10:
	lpush 1
	ifgt next11
	hlt
next11:
	lpush -1
	iflt next12
	hlt
next12:
	goto next13
	hlt
next13:
	getsp
	ifeq ok
	hlt
ok:	wfi
