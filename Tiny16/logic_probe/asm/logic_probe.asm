.equ RAM_SIZE 4096

.equ I2C_PORT 0
.equ LOGIC_PROBE_PORT $4000
.equ DAC1_PORT $8000
.equ DAC2_PORT $C000

.equ I2C_WAIT_COUNTER 15
.equ SCL_BIT 2
.equ SDA_BIT 1

.equ LCD_WIDTH  128
.equ LCD_HEIGHT 32

	jmp start
	reti
.constants
start:
	mov r0, RAM_SIZE
	loadsp  r0
	mov r15, I2C_PORT
	call ssd1306_init
	call lcd_clear_screen
	clr r15 ; char
	clr r14 ; x
	clr r13 ; y
	call lcd_draw_char
	mov r15, 1 ; char
	inc r14 ; x
	call lcd_draw_char
	call lcd_update
	hlt
