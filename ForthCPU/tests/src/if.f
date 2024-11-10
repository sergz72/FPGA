: isr1 ;
: isr2 ;

: main
  0 if hlt then
  1 if0 hlt then

  1 if 2 else 4 then
  2 != if hlt then
  0 if 2 else 4 then
  4 != if hlt then

  1 if0 2 else 4 then
  4 != if hlt then
  0 if0 2 else 4 then
  2 != if hlt then

  sp@ if hlt then

  wfi
;
