: isr1 ;
: isr2 ;

hex
: main FFEF 30 and
  20 != if hlt then
  wfi
;
