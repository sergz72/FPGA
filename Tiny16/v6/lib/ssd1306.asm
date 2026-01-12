.segment code

.equ SSD1306_SETCONTRAST $8100
.equ SSD1306_DISPLAYALLON_RESUME $A400
.equ SSD1306_DISPLAYALLON $A500
.equ SSD1306_NORMALDISPLAY $A600
.equ SSD1306_INVERTDISPLAY $A700
.equ SSD1306_DISPLAYOFF $AE00
.equ SSD1306_DISPLAYON $AF00

.equ SSD1306_SETDISPLAYOFFSET $D300
.equ SSD1306_SETCOMPINS $DA00

.equ SSD1306_SETVCOMDETECT $DB00

.equ SSD1306_SETDISPLAYCLOCKDIV $D500
.equ SSD1306_SETPRECHARGE $D900

.equ SSD1306_SETMULTIPLEX $A800

.equ SSD1306_SETLOWCOLUMN $00
.equ SSD1306_SETHIGHCOLUMN $1000

.equ SSD1306_SETSTARTLINE $4000

.equ SSD1306_MEMORYMODE $2000
.equ SSD1306_COLUMNADDR $2100
.equ SSD1306_PAGEADDR   $2200

.equ SSD1306_COMSCANINC $C000
.equ SSD1306_COMSCANDEC $C800

.equ SSD1306_SEGREMAP $A000

.equ SSD1306_CHARGEPUMP $8D00

.equ LCD_MAX_CONTRAST $8F

.equ LCD_BUFFER_SIZE LCD_WIDTH * LCD_HEIGHT / 8

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
    call i2c_master_write2
    mov r13, SSD1306_SETDISPLAYCLOCKDIV
    call i2c_master_write2
    mov r13, $8000 ;the suggested ratio 0x80
    call i2c_master_write2
    mov r13, SSD1306_SETMULTIPLEX
    call i2c_master_write2
    mov r13, (LCD_HEIGHT - 1) << 8
    call i2c_master_write2
    mov r13, SSD1306_SETDISPLAYOFFSET
    call i2c_master_write2
    clr r13 ; no offset
    call i2c_master_write2
    mov r13, SSD1306_SETSTARTLINE ; line 0
    call i2c_master_write2
    mov r13, SSD1306_CHARGEPUMP
    call i2c_master_write2
    mov r13,$1400 ; internal vcc
    call i2c_master_write2
    mov r13, SSD1306_MEMORYMODE
    call i2c_master_write2
    clr r13 ; 0 - act like ks0108
    call i2c_master_write2
    mov r13, SSD1306_SEGREMAP | $100
    call i2c_master_write2
    mov r13, SSD1306_COMSCANDEC
    call i2c_master_write2

    mov r13, SSD1306_SETCOMPINS
    call i2c_master_write2
.if LCD_HEIGHT == 32
    mov r13, $200
    call i2c_master_write2
    mov r13, SSD1306_SETCONTRAST
    call i2c_master_write2
    mov r13, LCD_MAX_CONTRAST << 8
    call i2c_master_write2
.endif
.if LCD_HEIGHT == 64
    mov r13, $1200
    call i2c_master_write2
    mov r13, SSD1306_SETCONTRAST
    call i2c_master_write2
    mov r13, $CF00
    call i2c_master_write2
.endif
.if LCD_HEIGHT == 16
    mov r13, $200
    call i2c_master_write2
    mov r13, SSD1306_SETCONTRAST
    call i2c_master_write2
    mov r13, $AF00
    call i2c_master_write2
.endif

    mov r13, SSD1306_SETPRECHARGE
    call i2c_master_write2
    mov r13, $F100
    call i2c_master_write2
    mov r13, SSD1306_SETVCOMDETECT
    call i2c_master_write2
    mov r13, $4000
    call i2c_master_write2
    mov r13, SSD1306_DISPLAYALLON_RESUME
    call i2c_master_write2
    mov r13, SSD1306_NORMALDISPLAY
    call i2c_master_write2
    mov r13, SSD1306_DEACTIVATE_SCROLL
    call i2c_master_write2
    mov r13, SSD1306_DISPLAYON
    call i2c_master_write2
    ret

lcd_update:
    mov r14, SSD1306_I2C_ADDRESS
    mov r13, SSD1306_COLUMNADDR
    call i2c_master_write2
    clr r13
    call i2c_master_write2
    mov r13, (LCD_WIDTH - 1) << 8
    call i2c_master_write2
    mov r13, SSD1306_PAGEADDR
    call i2c_master_write2
    clr r13
    call i2c_master_write2
.if LCD_HEIGHT == 64
    mov r13, $700
.endif
.if LCD_HEIGHT == 32
    mov r13, $300
.endif
.if LCD_HEIGHT == 16
    mov r13, $100
.endif
    call i2c_master_write2
    
    mov r5, LCD_BUFFER_SIZE
    lda r6, lcd_buffer
ssd1306_write_next:
    mov r14, SSD1306_I2C_ADDRESS
    mov r13, $40
    call i2c_master_write_nostop
    mov r7, 16
ssd1306_write_next_byte:
    mov r14, @r6
    call i2c_send_byte
    inc r6
    dec r7
    bne ssd1306_write_next_byte
    call i2c_stop
    sub r5, 16
    bgt ssd1306_write_next
    ret

lcd_clear_screen:
    mov r15, LCD_BUFFER_SIZE
    lda r14, lcd_buffer
    clr r13
lcd_clear_screen_next:
    mov @r14, r13
    inc r14
    dec r15
    bne lcd_clear_screen_next
    ret

.segment bss
lcd_buffer: resw LCD_BUFFER_SIZE
