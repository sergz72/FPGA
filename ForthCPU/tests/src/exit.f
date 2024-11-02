: isr1 ;
: isr2 ;

: test_exit 1 exit 2 ;

: main test_exit
  1 != if hlt then
  wfi
;
