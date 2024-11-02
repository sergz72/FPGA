: isr1 ;
: isr2 ;

: main 1 2 3 rot
  1 != if hlt then
  2 != if hlt then
  3 != if hlt then
  wfi
;
