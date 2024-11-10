: isr1 ;
: isr2 ;

: main 1 2 3
  3 != if hlt then
  2 != if hlt then
  1 != if hlt then
  sp@ if hlt then
  wfi
;
