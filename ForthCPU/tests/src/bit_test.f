: isr1 ;
: isr2 ;

hex
: main
  FF 7 bit?
  1 != if hlt then
  7F 7 bit? if hlt then
  FFFF F bit?
  1 != if hlt then
  7FFF F bit? if hlt then
  wfi
;
decimal
