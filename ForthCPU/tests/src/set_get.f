variable test

: isr1 ;
: isr2 ;

: main 1 test ! test @ 1 + test !
  test @
  2 != if hlt then
  sp@ if hlt then
  wfi
;
