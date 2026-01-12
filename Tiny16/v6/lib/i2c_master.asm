.segment code

.def i2c_address r14
.def i2c_byte12 r13
.def i2c_port_address r15
.def i2c_wait_counter r12
.def i2c_mask r11
.def i2c_bit_counter r10
.def i2c_temp r9
.def i2c_ack r8

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
    test i2c_address, i2c_mask
    beq i2c_send0
    or  i2c_temp, SDA_BIT
i2c_send0:
    out @i2c_port_address, i2c_temp
.if I2C_WAIT_COUNTER > 0
    call i2c_wait
.endif
    or i2c_temp, SCL_BIT
    out @i2c_port_address, i2c_temp ; scl high
.if I2C_WAIT_COUNTER > 0
    call i2c_wait
.endif
    and i2c_temp, ~SCL_BIT
    out @i2c_port_address, i2c_temp ; scl low
    ret

i2c_send_byte:
    mov i2c_bit_counter, 8
i2c_send_byte_loop:
    call i2c_send_bit
    shl i2c_address, i2c_address
    dec i2c_bit_counter
    bne i2c_send_byte_loop
    mov i2c_address, i2c_mask
    call i2c_send_bit ; ack
    ret

i2c_read_bit:
    mov i2c_temp, SDA_BIT
    out @i2c_port_address, i2c_temp ; sda high
.if I2C_WAIT_COUNTER > 0
    call i2c_wait
.endif
    mov i2c_temp, SCL_BIT | SDA_BIT
    out @i2c_port_address, i2c_temp ; scl high
.if I2C_WAIT_COUNTER > 0
    call i2c_wait
.endif

    in i2c_temp, @i2c_port_address
    and i2c_temp, SDA_BIT
    or  i2c_address, i2c_temp

    mov i2c_temp, SDA_BIT
    out @i2c_port_address, i2c_temp ; scl low
.if I2C_WAIT_COUNTER > 0
    call i2c_wait
.endif
    ret

; output byte in r13
i2c_read_byte:
    mov i2c_bit_counter, 8
    clr i2c_address
i2c_read_byte_loop:
    shl i2c_address, i2c_address
    call i2c_read_bit
    dec i2c_bit_counter
    bne i2c_read_byte_loop
    mov  i2c_byte12, i2c_address
    mov i2c_address, i2c_ack
    call i2c_send_bit ; ack
    mov i2c_temp, SDA_BIT
    out @i2c_port_address, i2c_temp ; sda high
.if I2C_WAIT_COUNTER > 0
    call i2c_wait
.endif
    ret
    
i2c_start:
    mov i2c_temp, SCL_BIT
    out @i2c_port_address, i2c_temp ; sda low
.if I2C_WAIT_COUNTER > 0
    call i2c_wait
.endif
    clr i2c_temp
    out @i2c_port_address, i2c_temp ; scl low
; address
    call i2c_send_byte
    ret

i2c_master_write_nostop:
    push i2c_address
    mov i2c_mask, $80
    call i2c_start
    mov i2c_address, i2c_byte12
    call i2c_send_byte
    pop i2c_address
    ret

i2c_master_write1:
    push i2c_address
    mov i2c_mask, $80
    call i2c_start
    jmp i2c_w1

i2c_master_write2:
    push i2c_address
    mov i2c_mask, $80
    call i2c_start
    mov i2c_address, i2c_byte12
; byte1
    call i2c_send_byte
    shr i2c_byte12, i2c_byte12
    shr i2c_byte12, i2c_byte12
    shr i2c_byte12, i2c_byte12
    shr i2c_byte12, i2c_byte12
    shr i2c_byte12, i2c_byte12
    shr i2c_byte12, i2c_byte12
    shr i2c_byte12, i2c_byte12
    shr i2c_byte12, i2c_byte12
; byte2
i2c_w1:
    mov i2c_address, i2c_byte12
    call i2c_send_byte
i2c_stop_pop:
    call i2c_stop
    pop i2c_address
    ret

i2c_stop:
.if I2C_WAIT_COUNTER > 0
    call i2c_wait
.endif
    clr i2c_temp
    out @i2c_port_address, i2c_temp ; sda low
.if I2C_WAIT_COUNTER > 0
    call i2c_wait
.endif
    mov i2c_temp, SCL_BIT
    out @i2c_port_address, i2c_temp ; scl high
.if I2C_WAIT_COUNTER > 0
    call i2c_wait
.endif
    mov i2c_temp, SCL_BIT | SDA_BIT
    out @i2c_port_address, i2c_temp ; sda high
.if I2C_WAIT_COUNTER > 0
    call i2c_wait
    call i2c_wait
.endif
    ret

; out in r15
i2c_master_read2:
    push i2c_address
    mov i2c_mask, $80
    or   i2c_address, 1
    call i2c_start
; byte1
    clr i2c_ack
    call i2c_read_byte
    mov i2c_port_address, i2c_byte12
    shl i2c_port_address, i2c_port_address
    shl i2c_port_address, i2c_port_address
    shl i2c_port_address, i2c_port_address
    shl i2c_port_address, i2c_port_address
    shl i2c_port_address, i2c_port_address
    shl i2c_port_address, i2c_port_address
    shl i2c_port_address, i2c_port_address
    shl i2c_port_address, i2c_port_address
; byte2
    mov i2c_ack, $80
    call i2c_read_byte
    or i2c_port_address, i2c_byte12
    jmp i2c_stop_pop
