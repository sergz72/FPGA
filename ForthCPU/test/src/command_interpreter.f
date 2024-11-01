variable address
variable length

: err 'E' uart_out '\r' uart_out '\n' uart_out ;
: ok 'K' uart_out '\r' uart_out '\n' uart_out ;

: command2 ok ;

: interpret_command
  command command_read_p !
  command_p @ command_read_p @ != if
    command_read_p @ @
    command_read_p @ 1 + command_read_p !
    case
      't' of ram_test endof
      'e' of command2 endof
      drop err
    endcase
  then
;
