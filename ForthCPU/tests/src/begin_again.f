: isr1 ;
: isr2 ;

: main 2
  begin 3 + dup 20 > if leave then again
  23 != if hlt then
  sp@ if hlt then
  wfi
;
