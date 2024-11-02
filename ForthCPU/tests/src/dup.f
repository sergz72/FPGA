: isr1 ;
: isr2 ;

: main 1 2 dup
  2 != if hlt then
  2 != if hlt then
  1 != if hlt then
  wfi
;
