	ipush 1
	ipush 1
	ifcmpeq next1
	hlt
next1:
	ipush 1
	ipush 1
	ifcmpge next2
	hlt
next2:
	ipush 1
	ipush 1
	ifcmple next3
	hlt
next3:
        ipush 1
	ipush 2
	ifcmpne next4
	hlt
next4:
        ipush 1
	ipush 2
	ifcmplt next5
	hlt
next5:
        ipush 2
	ipush 1
	ifcmpgt next6
	hlt
next6:
	ipush 0
	ifeq next7
	hlt
next7:
	ipush 0
	ifge next8
	hlt
next8:
	ipush 0
	ifle next9
	hlt
next9:
	ipush 1
	ifne next10
	hlt
next10:
	ipush 1
	ifgt next11
	hlt
next11:
	ipush -1
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
