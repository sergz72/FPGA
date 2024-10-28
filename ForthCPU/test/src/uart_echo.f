hex FFFF constant PORT
hex EFFF constant UART
decimal 128 constant MAX_COMMAND_LENGTH

variable led_state
variable timer_interrupt
variable command_p
variable command_read_p
variable command MAX_COMMAND_LENGTH
variable command_ready
command MAX_COMMAND_LENGTH + constant COMMAND_END

: isr1 1 timer_interrupt! ;

: isr2
  UART @
  command_ready @ if0
    command_p @ COMMAND_END < if
      dup
      command_p @ ! command_p @ 1 + command_p !
    then
    '\r' = if
      1 command_ready !
    then
  else
    drop
  then
;

: blink led_state @ dup PORT ! 1+ led_state ! ;

: uart_out begin UART @ hex 100 & until UART ! ;

: uart_echo begin command_read_p command_p != while
    command_read_p @ dup @ uart_out
    1 + command_read_p !
  repeat
;

: main 
  0 led_state !
  command command_p !
  command command_read_p !
  0 command_ready !
  0 timer_interrupt !
  begin
    wfi blink
    timer_interrupt @ if
      uart_echo
      0 timer_interrupt !
    then
    command_ready @ if
      command command_p !
      command command_read_p !
      0 command_ready !
    then
  again
;
