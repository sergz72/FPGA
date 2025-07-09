.segment code

.equ SSD1306_SETCONTRAST $81
.equ SSD1306_DISPLAYALLON_RESUME $A4
.equ SSD1306_DISPLAYALLON $A5
.equ SSD1306_NORMALDISPLAY $A6
.equ SSD1306_INVERTDISPLAY $A7
.equ SSD1306_DISPLAYOFF $AE
.equ SSD1306_DISPLAYON $AF

.equ SSD1306_SETDISPLAYOFFSET $D3
.equ SSD1306_SETCOMPINS $DA

.equ SSD1306_SETVCOMDETECT $DB

.equ SSD1306_SETDISPLAYCLOCKDIV $D5
.equ SSD1306_SETPRECHARGE $D9

.equ SSD1306_SETMULTIPLEX $A8

.equ SSD1306_SETLOWCOLUMN $00
.equ SSD1306_SETHIGHCOLUMN $10

.equ SSD1306_SETSTARTLINE $40

.equ SSD1306_MEMORYMODE $20
.equ SSD1306_COLUMNADDR $21
.equ SSD1306_PAGEADDR   $22

.equ SSD1306_COMSCANINC $C0
.equ SSD1306_COMSCANDEC $C8

.equ SSD1306_SEGREMAP $A0

.equ SSD1306_CHARGEPUMP $8D

.equ LCD_MAX_CONTRAST $8F

.equ LCD_BUFFER_SIZE LCD_WIDTH * LCD_HEIGHT / 16

; Scrolling .equs
.equ SSD1306_ACTIVATE_SCROLL $2F
.equ SSD1306_DEACTIVATE_SCROLL $2E
.equ SSD1306_SET_VERTICAL_SCROLL_AREA $A3
.equ SSD1306_RIGHT_HORIZONTAL_SCROLL $26
.equ SSD1306_LEFT_HORIZONTAL_SCROLL $27
.equ SSD1306_VERTICAL_AND_RIGHT_HORIZONTAL_SCROLL $29
.equ SSD1306_VERTICAL_AND_LEFT_HORIZONTAL_SCROLL $2A

.equ SSD1306_I2C_ADDRESS $78

ssd1306_init:
    mov r14, SSD1306_I2C_ADDRESS
    mov r13, SSD1306_DISPLAYOFF
    call i2c_master_write1
    mov r13, SSD1306_SETDISPLAYCLOCKDIV
    call i2c_master_write1
    mov r13, $80 ;the suggested ratio 0x80
    call i2c_master_write1
    mov r13, SSD1306_SETMULTIPLEX
    call i2c_master_write1
    mov r13, LCD_HEIGHT - 1
    call i2c_master_write1
    mov r13, SSD1306_SETDISPLAYOFFSET
    call i2c_master_write1
    clr r13 ; no offset
    call i2c_master_write1
    mov r13, SSD1306_SETSTARTLINE ; line 0
    call i2c_master_write1
    mov r13, SSD1306_CHARGEPUMP
    call i2c_master_write1
    mov r13,$14 ; internal vcc
    call i2c_master_write1
    mov r13, SSD1306_MEMORYMODE
    call i2c_master_write1
    clr r13 ; 0 - act like ks0108
    call i2c_master_write1
    mov r13, SSD1306_SEGREMAP | 1
    call i2c_master_write1
    mov r13, SSD1306_COMSCANDEC
    call i2c_master_write1

    mov r13, SSD1306_SETCOMPINS
    call i2c_master_write1
.if LCD_HEIGHT == 32
    mov r13, 2
    call i2c_master_write1
    mov r13, SSD1306_SETCONTRAST
    call i2c_master_write1
    mov r13, LCD_MAX_CONTRAST
    call i2c_master_write1
.endif
.if LCD_HEIGHT == 64
    mov r13, $12
    call i2c_master_write1
    mov r13, SSD1306_SETCONTRAST
    call i2c_master_write1
    mov r13, $CF
    call i2c_master_write1
.endif
.if LCD_HEIGHT == 16
    mov r13, 2
    call i2c_master_write1
    mov r13, SSD1306_SETCONTRAST
    call i2c_master_write1
    mov r13, $AF
    call i2c_master_write1
.endif

    mov r13, SSD1306_SETPRECHARGE
    call i2c_master_write1
    mov r13, $F1
    call i2c_master_write1
    mov r13, SSD1306_SETVCOMDETECT
    call i2c_master_write1
    mov r13, $40
    call i2c_master_write1
    mov r13, SSD1306_DISPLAYALLON_RESUME
    call i2c_master_write1
    mov r13, SSD1306_NORMALDISPLAY
    call i2c_master_write1
    mov r13, SSD1306_DEACTIVATE_SCROLL
    call i2c_master_write1
    mov r13, SSD1306_DISPLAYON
    call i2c_master_write1
    ret

lcd_update:
    mov r14, SSD1306_I2C_ADDRESS
    mov r13, SSD1306_COLUMNADDR
    call i2c_master_write1
    clr r13
    call i2c_master_write1
    mov r13, LCD_WIDTH - 1
    call i2c_master_write1
    mov r13, SSD1306_PAGEADDR
    call i2c_master_write1
    clr r13
    call i2c_master_write1
.if LCD_HEIGHT == 64
    mov r13, 7
.endif
.if LCD_HEIGHT == 32
    mov r13, 3
.endif
.if LCD_HEIGHT == 16
    mov r13, 1
.endif
    call i2c_master_write1
    
    mov r5, LCD_BUFFER_SIZE
    lda r6, lcd_buffer
ssd1306_write_next:
    mov r13, $40
    call i2c_master_write_nostop
    mov r7, 16
ssd1306_write_next_byte:
    mov r13, @r6
    call i2c_send_byte
    inc r6
    dec r7
    bne ssd1306_write_next_byte
    call i2c_stop
    sub r5, 16
    bge ssd1306_write_next
    ret

.segment bss
lcd_buffer: resw LCD_BUFFER_SIZE
