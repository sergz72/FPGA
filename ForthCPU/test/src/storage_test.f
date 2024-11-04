11 constant c
variable v
1 ivariable iv
array a 10
1 2 3 iarray ia 3
"test string" sconstant s
3 2 1 carray ca 3
33 23 13 carray ca2 3

: isr1 ;
: isr2 ;

: main c v ! c iv ! c a ! c ia ! ca @ ca2 @ s @ ;
