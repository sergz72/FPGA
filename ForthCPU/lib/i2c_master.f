2 constant SCL
1 constant SDA
3 constant SCLSDA

: i2c_delay
  6 0 do loop
;

\ channel data
: i2c_channel_set
  swap I2C_ADDRESS + !
;

\ data channel
: i2c_channel_set2
  I2C_ADDRESS + !
;

\ stack: channel
: i2c_start
  dup SCLSDA i2c_channel_set
  dup SCL i2c_channel_set \ sda low
  i2c_delay
  0 i2c_channel_set \ scl low
;

\ stack: channel
: i2c_stop
  dup 0 i2c_channel_set \ scl low sda low
  i2c_delay
  dup SCL i2c_channel_set \ scl high
  i2c_delay
  SCLSDA i2c_channel_set \ sda high
;

\ stack: byte channel -> byte channel
: i2c_bit_send
  locals state
  over \ byte, channel, byte
  7 bit? dup state!
  over \ byte, channel, flag, channel
  i2c_channel_set2
  dup state@ SCL or
  i2c_channel_set
  i2c_delay
  dup state@
  i2c_channel_set
;

\ stack: byte channel -> ack
: i2c_byte_send
  8 0 do
    i2c_bit_send
    swap 1 lshift swap
  loop
  swap \ channel byte
  drop \ channel
  dup  \ channel channel
  SDA i2c_channel_set \ sda high
  dup
  SCLSDA i2c_channel_set \ scl high
  i2c_delay
  dup
  I2C_ADDRESS + @ SDA and \ ack
  swap
  SDA i2c_channel_set \ scl low
;

\ stack: channel -> channel bit
: i2c_bit_read
  dup \ channel channel
  i2c_delay
  SCLSDA i2c_channel_set \ channel
  i2c_delay
  dup I2C_ADDRESS + @ SDA and \ channel bit
  over \ channel bit channel
  SDA i2c_channel_set \ channel bit
;

\ stack: ack channel -> byte
: i2c_byte_read
  locals data
  0 data!
  8 0 do
    i2c_bit_read
    data@ 1 lshift or data!
  loop
  i2c_bit_send
  drop drop data@
;

\ address channel -> channel ack
: i2c_send_address
  dup i2c_start
  dup \ address channel channel
  rot \ channel channel address
  rot \ channel address channel
  i2c_byte_send \ channel ack
;

\ channel address -> ack
: i2c_check
  1 lshift swap
  i2c_send_address
  swap \ ack channel
  i2c_stop \ ack
;

\ channel
: i2c_restart
  dup SDA i2c_channel_set
  i2c_delay
  dup SCLSDA i2c_channel_set
  i2c_delay
  i2c_start
;

\ read_address read_count write_address write_count channel address -> ack
\ read_count and write_count > 0
: i2c_transfer
  locals channel,address,last

  dup address!
  1 lshift
  i2c_send_address \ ... write_count channel ack
  if
    i2c_stop
    2drop 2drop 1
  else
    channel!
    0 do
      dup @ channel@ i2c_byte_send \ ... write_address ack
      if channel@ i2c_stop drop 2drop 1 exit then
      1 +
    loop
    drop \ read_address read_count
    channel@ dup i2c_restart address@ 1 + i2c_send_address
    if
      i2c_stop 2drop 1
    else
      dup 1 - last!
      0 do
        dup
        I last@ = if 1 else 0 then \ ack/nack
        channel@ i2c_byte_read
        ! 1 +
      loop
      drop
      channel@ i2c_stop
      0
    then
  then
;
