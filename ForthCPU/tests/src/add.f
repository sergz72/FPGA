: isr1 ;
: isr2 ;

: main 1 2 +
  3 != if hlt then
  wfi
;
