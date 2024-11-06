: isr1 ;
: isr2 ;

: test_exit 1 exit 2 ;

: test_exit2 1 10 0 do 3 + dup 21 > if exit then loop ;

: test_exit3 1 10 0 do test_exit2 + loop ;

: main test_exit
  1 != if hlt then
  test_exit3
  221 != if hlt then
  wfi
;
