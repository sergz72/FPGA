: isr1 ;
: isr2 ;

: main 22 5 mod
  2 != if hlt then
  wfi
;
