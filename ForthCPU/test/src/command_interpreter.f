1 constant I2C_CHANNELS
1 constant KNOWN_DEVICES
'A' 10 - constant A10
20 constant COMMAND_PART_LENGTH
6 constant COMMAND_PARTS
COMMAND_PART_LENGTH COMMAND_PARTS * constant COMMAND_PARTS_LENGTH

"i2c_test" sconstant I2C_TEST

array command_parts COMMAND_PARTS_LENGTH
variable command_parts_count

hex 5E carray known_devices KNOWN_DEVICES decimal

\ channel > device_id
: i2c_test_channel
  KNOWN_DEVICES 0 do
    I known_devices + @ \ channel device_id
    over \ channel device_id channel
    over \ channel device_id channel device_id
    i2c_check \ channel device_id ack
    if0 swap drop exit then
    drop \ channel
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

\ idx -> reference
: command_part
  COMMAND_PART_LENGTH * command_parts +
;

: split_command
  locals command_part_p,start

  0 command_parts_count !
  0 start!
  begin command_p @ command_read_p @ != while
    command_read_p @ @
    command_read_p @ 1 + command_read_p !
    dup 32 > if
       start@ if0
         command_parts_count @ command_part 1 + command_part_p!
         command_parts_count @ 1 + command_parts_count !
       then
       command_part_p@ !
       command_part_p@ 1 + command_part_p!
       1 start!
    else
      drop
      start@ if
        command_parts_count @ 1 - command_part dup 1 + \ cp cp+1
        command_part_p@ swap \ cp cpp cp+1
        - \ cp l
        swap ! \ save string length
      then
      0 start!
    then
  repeat
  start@ if
    command_parts_count @ 1 - command_part dup 1 + \ cp cp+1
    command_part_p@ swap \ cp cpp cp+1
    - \ cp l
    swap ! \ save string length
  then
;

: interpret_command
  command command_read_p !
  command_p @ command_read_p @ != if
    split_command
\    command_parts_count @ dup h. cr
\    0 do I command_part s. cr loop
    0 command_part case
      I2C_TEST compare 0 of i2c_test endof
      drop drop err
    endcase
  then
;
