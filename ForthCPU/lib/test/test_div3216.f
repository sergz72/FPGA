: isr1 ;
: isr2 ;

hex
: main
  AAAA 5555 1234 div3216
  0F69 != if hlt then
  6027 != if hlt then
  0009 != if hlt then
  wfi
;
