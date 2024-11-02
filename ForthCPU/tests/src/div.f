: isr1 ;
: isr2 ;

: main 20 5 /
  4 != if hlt then
  wfi
;
