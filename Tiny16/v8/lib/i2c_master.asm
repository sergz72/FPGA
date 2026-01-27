.segment code

.def i2c_address r0
.def i2c_byte12 r1
.def i2c_data r2
.def i2c_ack r3

.def i2c_wait_counter r64
.def i2c_temp r64
.def i2c_bit_counter r64

.if I2C_WAIT_COUNTER > 0
i2c_wait:
    mov i2c_wait_counter, I2C_WAIT_COUNTER
i2c_wait_loop:    
    dec i2c_wait_counter
    bne i2c_wait_loop
    ret
.endif

i2c_send_bit:
    clr i2c_temp
    test i2c_data, i2c_ack
    beq i2c_send0
    or  i2c_temp, SDA_BIT
i2c_send0:
    out I2C_PORT, i2c_temp
.if I2C_WAIT_COUNTER > 0
    call i2c_wait
.endif
    or i2c_temp, SCL_BIT
    out I2C_PORT, i2c_temp ; scl high
.if I2C_WAIT_COUNTER > 0
    call i2c_wait
.endif
    and i2c_temp, ~SCL_BIT
    out I2C_PORT, i2c_temp ; scl low
    ret

i2c_send_byte:
    mov i2c_bit_counter, 8
i2c_send_byte_loop:
    call i2c_send_bit
    shl i2c_data
    dec i2c_bit_counter
    bne i2c_send_byte_loop
    mov i2c_data, i2c_ack
    call i2c_send_bit ; ack
    ret

i2c_read_bit:
    mov i2c_temp, SDA_BIT
    out I2C_PORT, i2c_temp ; sda high
.if I2C_WAIT_COUNTER > 0
    call i2c_wait
.endif
    mov i2c_temp, SCL_BIT | SDA_BIT
    out I2C_PORT, i2c_temp ; scl high
.if I2C_WAIT_COUNTER > 0
    call i2c_wait
.endif

    in i2c_temp, I2C_PORT
    and i2c_temp, SDA_BIT
    or  i2c_data, i2c_temp

    mov i2c_temp, SDA_BIT
    out I2C_PORT, i2c_temp ; scl low
.if I2C_WAIT_COUNTER > 0
    call i2c_wait
.endif
    ret

; output byte in r1
i2c_read_byte:
    mov i2c_bit_counter, 8
    clr i2c_data
i2c_read_byte_loop:
    shl i2c_data
    call i2c_read_bit
    dec i2c_bit_counter
    bne i2c_read_byte_loop
    mov  i2c_byte12, i2c_data
    mov i2c_data, i2c_ack
    call i2c_send_bit ; ack
    mov i2c_temp, SDA_BIT
    out I2C_PORT, i2c_temp ; sda high
.if I2C_WAIT_COUNTER > 0
    call i2c_wait
.endif
    ret
    
i2c_start:
    mov i2c_temp, SCL_BIT
    out I2C_PORT, i2c_temp ; sda low
.if I2C_WAIT_COUNTER > 0
    call i2c_wait
.endif
    clr i2c_temp
    out I2C_PORT, i2c_temp ; scl low
; address
    call i2c_send_byte
    ret

i2c_master_write_nostop:
    ser i2c_ack
    mov i2c_data, i2c_address
    call i2c_start
    mov i2c_data, i2c_byte12
    call i2c_send_byte
    ret

i2c_master_write1:
    ser i2c_ack
    mov i2c_data, i2c_address
    call i2c_start
    mov i2c_data, i2c_byte12
; byte1
    call i2c_send_byte
    call i2c_stop
    ret

i2c_master_write2:
    ser i2c_ack
    mov i2c_data, i2c_address
    call i2c_start
    mov i2c_data, i2c_byte12
; byte1
    call i2c_send_byte
    mov i2c_data, i2c_byte12
    swab i2c_data
; byte2
    call i2c_send_byte
    call i2c_stop
    ret

i2c_stop:
.if I2C_WAIT_COUNTER > 0
    call i2c_wait
.endif
    clr i2c_temp
    out I2C_PORT, i2c_temp ; sda low
.if I2C_WAIT_COUNTER > 0
    call i2c_wait
.endif
    mov i2c_temp, SCL_BIT
    out I2C_PORT, i2c_temp ; scl high
.if I2C_WAIT_COUNTER > 0
    call i2c_wait
.endif
    mov i2c_temp, SCL_BIT | SDA_BIT
    out I2C_PORT, i2c_temp ; sda high
.if I2C_WAIT_COUNTER > 0
    call i2c_wait
    call i2c_wait
.endif
    ret

i2c_master_read2:
    ser i2c_ack
    mov i2c_data, i2c_address
    or   i2c_data, 1
    call i2c_start
; byte1
    clr i2c_ack
    call i2c_read_byte
    mov i2c_temp, i2c_byte12
    swab i2c_temp
; byte2
    ser i2c_ack
    call i2c_read_byte
    or i2c_byte12, i2c_temp
    call i2c_stop
    ret
