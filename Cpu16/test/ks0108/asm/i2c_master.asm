.def address r16
.def byte12 r17

.equ I2C_PORT_ADDRESS $4000
.equ I2C_WAIT_COUNTER 135 ; 100 kHz

i2c_wait:
    mov r21, I2C_WAIT_COUNTER
i2c_wait_loop:    
    dec r21
    jmpnz i2c_wait_loop
    ret

i2c_send_bit:
    test r16, $80
    jmpnz i2c_send1
    clr r19
    jmp i2c_send2
i2c_send1:
    mov r19, 2
i2c_send2:    
    out [r20], r19
    call i2c_wait
    or r19, 1
    out [r20], r19 ; scl high
    call i2c_wait
    and r19, $FE
    out [r20], r19 ; scl low
    call i2c_wait
    ret

i2c_send_byte:
    mov r21, 8
i2c_send_byte_loop:
    call i2c_send_bit
    shl r16, 1
    dec r21
    jmpnz i2c_send_byte_loop
    mov r16, $80
    call i2c_send_bit ; ack
    ret

i2c_read_byte:
    mov r21, 8
i2c_read_byte_loop:    
    dec r21
    jmpnz i2c_read_byte_loop
    ret
    
i2c_start:
    mov r20, I2C_PORT_ADDRESS
    mov r19, 2
    out [r20], r19
    call i2c_wait ; sda low
    clr r19
    out [r20], r19 ; scl low
    call i2c_wait
; address
    call i2c_send_byte
    ret

i2c_master_write1:
    call i2c_start
    mov r16, r17
; byte1
    call i2c_send_byte
    jmp i2c_stop

i2c_master_write2:
    call i2c_start
    mov r16, r17
; byte1
    call i2c_send_byte
    shr r17, 8
; byte2
    mov r16, r17
    call i2c_send_byte
i2c_stop:
    mov r19, 1
    out [r20], r19 ; scl high
    call i2c_wait
    mov r19, 3
    out [r20], r19 ; scl high
    call i2c_wait
    ret

i2c_master_read2:
    call i2c_start
; byte1
    call i2c_read_byte
    mov r17, r16
    shl r17, 8
; byte2
    call i2c_read_byte
    or r17, r17, r16
    jmp i2c_stop
