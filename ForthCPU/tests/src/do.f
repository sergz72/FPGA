: isr1 ;
: isr2 ;

: do2 1 10 0 do 11 1 do I J * + loop loop ;

: main
  10 1 10 0 do 3 + loop
  31 != if hlt then
  10 != if hlt then

  10 1 10 0 do 3 + 2 +loop
  16 != if hlt then
  10 != if hlt then

  10 1 10 0 do I + loop
  46 != if hlt then
  10 != if hlt then

  10 1 10 0 do 11 1 do I J - + loop loop
  101 != if hlt then
  10 != if hlt then

  10 1 10 0 do 11 1 do I J * do2 + + loop loop
  250076 != if hlt then
  10 != if hlt then

  wfi
;
