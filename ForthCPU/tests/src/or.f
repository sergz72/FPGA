: isr1 ;
: isr2 ;

hex
: main 3FEF C010 or
  FFFF != if hlt then
  sp@ if hlt then
  wfi
;
