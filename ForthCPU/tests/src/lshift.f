: isr1 ;
: isr2 ;

hex
: main 10 3 lshift
  80 != if hlt then
  wfi
;
