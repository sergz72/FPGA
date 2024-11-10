: isr1 ;
: isr2 ;

: main 4 5 *
  20 != if hlt then
  alu_out2 if hlt then
  hex 5555 AAAA *
  1C72 != if hlt then
  alu_out2 38E3 != if hlt then
  decimal 
  sp@ if hlt then
  wfi
;
