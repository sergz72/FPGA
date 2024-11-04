: isr1 ;
: isr2 ;

: main 2
  begin dup 20 <= while 3 + repeat
  23 != if hlt then
  2
  begin dup 20 > while0 3 + repeat
  23 != if hlt then

  wfi
;
