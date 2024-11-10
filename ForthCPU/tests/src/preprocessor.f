0 constant ZERO
1 constant ONE

ZERO [IF] 5 [ELSE] 10 [THEN] constant TEST1
ONE  [IF] 2 [ELSE] 4  [THEN] constant TEST2

: isr1 ;
: isr2 ;

: main TEST1 TEST2 +
  12 != if hlt then
  sp@ if hlt then
  wfi
;
