: isr1 ;
: isr2 ;

: main
  10 1 10 0 do 3 + loop
  31 != if hlt then
  10 != if hlt then

  10 1 10 0 do I + loop
  46 != if hlt then
  10 != if hlt then

  wfi
;
