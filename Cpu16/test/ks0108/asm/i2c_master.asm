.include "main16x2.asmh"

.def address r16
.def byte12 r17

.equ I2C_PORT_ADDRESS $4000

.if I2C_WAIT_COUNTER > 0
i2c_wait:
    mov r21, I2C_WAIT_COUNTER
i2c_wait_loop:    
    dec r21
    jmpnz i2c_wait_loop
    ret
.endif

i2c_send_bit:
    test r16, $80
    jmpnz i2c_send1
    clr r19
    jmp i2c_send2
i2c_send1:
    mov r19, 2
i2c_send2:    
    out [r20], r19
.if I2C_WAIT_COUNTER > 0
    call i2c_wait
.endif
    or r19, 1
    out [r20], r19 ; scl high
.if I2C_WAIT_COUNTER > 0
    call i2c_wait
.endif
    and r19, $FE
    out [r20], r19 ; scl low
.if I2C_WAIT_COUNTER > 0
    call i2c_wait
.endif
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
.if I2C_WAIT_COUNTER > 0
    call i2c_wait ; sda low
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
    mov r16, byte12
; byte1
    call i2c_send_byte
    jmp i2c_stop

i2c_master_write2:
.if I2C_WAIT_COUNTER > 0
    call i2c_start
.endif
    mov r16, byte12
; byte1
    call i2c_send_byte
    shr byte12, 8
; byte2
    mov r16, byte12
    call i2c_send_byte
i2c_stop:
    mov r19, 1
    out [r20], r19 ; scl high
.if I2C_WAIT_COUNTER > 0
    call i2c_start
.endif
    mov r19, 3
    out [r20], r19 ; scl high
.if I2C_WAIT_COUNTER > 0
    call i2c_start
.endif
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
