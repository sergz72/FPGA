variable address
variable length
'a' 'A' - constant aA

: err 'E' uart_out '\r' uart_out '\n' uart_out ;
: ok 'K' uart_out '\r' uart_out '\n' uart_out ;

\ v v1 v2 -> 1/0
: between
  rot \ v1 v2 v
  dup \ v1 v2 v v
  rot \ v1 v v v2
  > if \ v1 v
    drop drop 0
  else
    <=
  then
;

: is_hex dup '0' '9' between if0
    dup
    'A' 'Z' between if0
      dup
      'A' 'Z' between if
        aA -
      else
        drop 0
      then
    then
  then
;

: read4 dup command_read_p @ @ dup is_hex if
  else
    0
  then
;

: ram_test 
  command_p @ command_read_p @ - 8 = if
    address read4 if
      length read4 if
        ok
      else
        err
      then
    else
      err
    then
  else
    err
  then
;

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
