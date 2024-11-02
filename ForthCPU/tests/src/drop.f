: isr1 ;
: isr2 ;

: main 1 2 3 drop
  2 != if hlt then
  1 != if hlt then
  wfi
;
