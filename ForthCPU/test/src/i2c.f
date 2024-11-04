2 constant SCL
1 constant SDA
3 constant SCLSDA

: i2c_channel_set
  I2C_ADDRESS + !
;

\ stack: channel
: i2c_start
  dup SCLSDA i2c_channel_set
  dup SCL i2c_channel_set \ sda low
  0 i2c_channel_set \ scl low
;

\ stack: channel
: i2c_stop
  dup 0 i2c_channel_set \ scl low sda low
  dup SCL i2c_channel_set \ scl high
  SCLSDA i2c_channel_set \ sda high
;

\ stack: byte channel -> byte channel
: i2c_bit_send
  locals state
  over \ byte, channel, byte
  128 and if SDA else 0 then dup state!
  over \ byte, channel, flag, channel
  i2c_channel_set
  dup state@ SCL or
  i2c_channel_set
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
  dup
  I2C_ADDRESS + @ SDA and \ ack
  swap
  SDA i2c_channel_set \ scl low
;

\ address channel -> ack
: i2c_check
  dup i2c_start
  dup rot \ channel address channel
  i2c_byte_send \ channel ack
  swap \ ack channel
  i2c_stop \ ack
;
