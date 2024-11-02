: isr1 ;
: isr2 ;

hex
: main 80 3 rshift
  10 != if hlt then
  wfi
;
