: isr1 ;
: isr2 ;

: main 2
  begin 3 + dup 20 <= until
  23 != if hlt then
  2
  begin 3 + dup 20 > until0
  23 != if hlt then

  wfi
;
