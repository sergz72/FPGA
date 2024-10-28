hex FFFF constant PORT
hex EFFF constant UART
variable led_state
variable timer_interrupt

: isr1 1 timer_interrupt! ;

: isr2
  UART @
  command_ready@ 0= if
    command_p@ ! command_p@ 1+ command_p!
  else
    drop
  then
;

: blink led_state@ dup PORT ! 1+ led_state! ;

: main 0 led_state!
  begin
    wfi blink uart_get
  again
;
