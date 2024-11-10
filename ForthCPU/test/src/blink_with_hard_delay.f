10000 constant DELAY \ 100 ms
hex 8000 constant TIMER
hex FFFF constant PORT decimal

0 ivariable led_state
0 ivariable timer_interrupt

: isr1 1 timer_interrupt ! ;
: isr2 ;

: blink led_state @ dup PORT ! 1 + led_state ! ;

: main
  DELAY TIMER !
  begin
    wfi
    timer_interrupt @ if
      0 timer_interrupt !
      blink
      DELAY TIMER !
    then
  again
;
