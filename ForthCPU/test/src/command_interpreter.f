2 constant I2C_CHANNELS
2 constant KNOWN_DEVICES

hex 60 62 carray known_devices KNOWN_DEVICES
decimal

: cr '\r' uart_out '\n' uart_out ;
: space 32 uart_out ;
: err 'E' uart_out cr ;
: ok 'K' uart_out cr ;

: hex_out
  hex F and decimal
  dup 9 > if 'A' else '0' then
  + uart_out
;

: h.
  dup 12 rshift hex_out
  dup 8 rshift hex_out
  dup 4 rshift hex_out
  hex_out
;

\ channel > device_id
: i2c_test_channel
  KNOWN_DEVICES 0 do
    I known_devices + @ \ channel device_id
    over \ channel device_id channel
    over \ channel device_id channel device_id
    i2c_check \ device_id channel ack
    if0 drop exit then
    swap drop \ channel
  loop
  drop 0
;

: i2c_test
  I2C_CHANNELS 0 do
    I i2c_test_channel
    h. space
  loop
  cr ok
;

: interpret_command
  command command_read_p !
  command_p @ command_read_p @ != if
    command_read_p @ @
    command_read_p @ 1 + command_read_p !
    case
      'i' of i2c_test endof
      drop err
    endcase
  then
;
