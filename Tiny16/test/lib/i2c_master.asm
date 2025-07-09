.def address r14
.def byte12 r15

.if I2C_WAIT_COUNTER > 0
i2c_wait:
    mov r13, I2C_WAIT_COUNTER
i2c_wait_loop:    
    dec r13
    bne i2c_wait_loop
    ret
.endif

i2c_send_bit:
    mov r19, r16
    shr r19, 7
    and r19, SDA_BIT
    out [r20], r19
.if I2C_WAIT_COUNTER > 0
    call i2c_wait
.endif
    or r19, SCL_BIT
    out [r20], r19 ; scl high
.if I2C_WAIT_COUNTER > 0
    call i2c_wait
.endif
    and r19, ~SCL_BIT
    out [r20], r19 ; scl low
.if I2C_WAIT_COUNTER > 0
    call i2c_wait
.endif
    ret

i2c_send_byte:
    mov r12, 8
i2c_send_byte_loop:
    call i2c_send_bit
    shl r14, r14
    dec r12
    jmpnz i2c_send_byte_loop
    mov r14, $80
    call i2c_send_bit ; ack
    ret

i2c_read_bit:
    mov r19, SDA_BIT
    out [r20], r19 ; sda high
.if I2C_WAIT_COUNTER > 0
    call i2c_wait
.endif
    mov r19, SCL_BIT | SDA_BIT
    out [r20], r19 ; scl high
.if I2C_WAIT_COUNTER > 0
    call i2c_wait
.endif

    in r18, [r20]
    and r18, SDA_BIT
    or  r16, r16, r18

    mov r19, SDA_BIT
    out [r20], r19 ; scl low
.if I2C_WAIT_COUNTER > 0
    call i2c_wait
.endif
    ret

; output byte in r18
i2c_read_byte:
    mov r21, 8
    clr r16
i2c_read_byte_loop:
    shl r16, 1
    call i2c_read_bit
    dec r21
    jmpnz i2c_read_byte_loop
    mov  r18, r16
    mov  r16, r23
    call i2c_send_bit ; ack
    mov r19, SDA_BIT
    out [r20], r19 ; sda high
.if I2C_WAIT_COUNTER > 0
    call i2c_wait
.endif
    ret
    
i2c_start:
    mov r20, I2C_PORT_ADDRESS
    mov r19, SCL_BIT
    out [r20], r19 ; sda low
.if I2C_WAIT_COUNTER > 0
    call i2c_wait
.endif
    clr r19
    out [r20], r19 ; scl low
.if I2C_WAIT_COUNTER > 0
    call i2c_wait
.endif
; address
    call i2c_send_byte
    ret

i2c_master_write1:
    call i2c_start
    jmp i2c_w1

i2c_master_write2:
    call i2c_start
    mov r16, byte12
; byte1
    call i2c_send_byte
    shr byte12, 8
; byte2
i2c_w1:
    mov r16, byte12
    call i2c_send_byte
i2c_stop:
    clr r19
    out [r20], r19 ; sda low
.if I2C_WAIT_COUNTER > 0
    call i2c_wait
.endif
    mov r19, SCL_BIT
    out [r20], r19 ; scl high
.if I2C_WAIT_COUNTER > 0
    call i2c_wait
.endif
    mov r19, SCL_BIT | SDA_BIT
    out [r20], r19 ; sda high
.if I2C_WAIT_COUNTER > 0
    call i2c_wait
.endif
    ret

; out in r17
i2c_master_read2:
    or   r16, 1
    call i2c_start
; byte1
    clr r23
    call i2c_read_byte
    mov r17, r18
    shl r17, 8
; byte2
    mov r23, $80
    call i2c_read_byte
    or r17, r17, r18
    jmp i2c_stop
