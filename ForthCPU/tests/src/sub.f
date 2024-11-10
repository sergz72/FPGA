: isr1 ;
: isr2 ;

: main 5 2 -
  3 != if hlt then
  sp@ if hlt then
  wfi
;
