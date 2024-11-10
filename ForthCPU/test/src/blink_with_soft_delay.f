hex FFFF constant PORT decimal

: isr1 ;
: isr2 ;

: delay 60000 0 do loop ;

: main 0 begin dup PORT ! 1 + delay again ;
