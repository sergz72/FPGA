: isr1 ;
: isr2 ;

: main 1 2 over
  1 != if hlt then
  2 != if hlt then
  1 != if hlt then
  wfi
;
