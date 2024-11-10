: isr1 ;
: isr2 ;

hex
: main 55AA AA55 xor
  FFFF != if hlt then
  sp@ if hlt then
  wfi
;
