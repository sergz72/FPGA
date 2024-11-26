: isr1 ;
: isr2 ;

: word1 1 ;
: word1 2 3 drop ;

hex
: main
  word1 2 != if hlt then
  sp@ if hlt then
  wfi
;
