10000 constant DELAY \ 100 ms
hex 8000 constant TIMER
hex A000 constant I2C_ADDRESS
hex FFFF constant PORT
hex CFFF constant UART
decimal 128 constant MAX_COMMAND_LENGTH

0 ivariable led_state
0 ivariable timer_interrupt
0 ivariable command_ready
variable command_p
variable command_read_p
variable command_end
array command MAX_COMMAND_LENGTH

: isr1 1 timer_interrupt ! ;

: isr2
  UART @
  command_ready @ if0
    command_p @ command_end @ < if
      dup
      '\r' = if
        command_ready !
      else
        command_p @ ! command_p @ 1 + command_p !
      then
    then
  else
    drop
  then
;

: blink led_state @ dup PORT ! 1 + led_state ! ;

: emit begin UART @ 256 and until UART ! ;

: uart_echo begin command_read_p @ command_p @ != while
    command_read_p @ dup @ emit
    1 + command_read_p !
  repeat
;

: main 
  command command_p !
  command command_read_p !
  command MAX_COMMAND_LENGTH + command_end !
  DELAY TIMER !
  begin
    wfi
    timer_interrupt @ if
      0 timer_interrupt !
      blink
      uart_echo

      command_ready @ if
        cr
        interpret_command
        command command_p !
        command command_read_p !
        0 command_ready !
      then
      DELAY TIMER !
    then
  again
;
