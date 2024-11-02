: isr1 ;
: isr2 ;

: main 4 5 *
  20 != if hlt then
  wfi
;
