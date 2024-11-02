: isr1 ;
: isr2 ;

: test_case
  case
    1 of 4 endof
    2 of 8 endof
    3 of 12 endof
    drop 16
  endcase
;

: main
  1 test_case
  4 != if hlt then

  2 test_case
  8 != if hlt then

  3 test_case
  12 != if hlt then

  0 test_case
  16 != if hlt then

  wfi
;
