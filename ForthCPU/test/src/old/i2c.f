\ stack: channel * 2
: sda_low
  I2C_ADDRESS_SDA + 0 swap !
;

\ stack: channel * 2
: scl_low
  I2C_ADDRESS_SCL + 0 swap !
;

\ stack: channel * 2
: sda_high
  I2C_ADDRESS_SDA + 1 swap !
;

\ stack: channel * 2
: scl_high
  I2C_ADDRESS_SCL + 1 swap !
;

\ stack: data channel * 2
: sda_set
  I2C_ADDRESS_SDA + !
;

\ stack: channel * 2
: i2c_start
  dup sda_low
  scl_low
;

\ stack: channel * 2
: i2c_stop
  dup scl_high
  sda_high
;

\ stack: byte channel * 2 -> byte channel * 2
: i2c_bit_send
  over \ byte, channel * 2, byte
  over \ byte, channel * 2, byte, channel * 2
  sda_set
  dup
  scl_high
  dup
  scl_low
;

\ stack: byte channel * 2 -> ack
: i2c_byte_send
  8 0 do
    i2c_bit_send
    swap 1 rshift swap
  loop
  swap \ channel byte
  drop \ channel
  dup  \ channel channel
  sda_high
  dup
  scl_high
  dup
  I2C_ADDRESS_SDA + @ \ ack
  swap
  scl_low
;

\ address channel * 2 -> ack
: i2c_check
  dup i2c_start
  i2c_byte_send
  swap
  i2c_stop
;
