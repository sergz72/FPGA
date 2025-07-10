.include "font.ah"

; row/col 0  1  2  3  4  5  6  7  8  9  10 11 12 13 14 15
; 0       F  H     0  0  0  .  0  0  0  .  0  0  0  H  z
; 1       F        0  0  0  .  0  0  0  .  0  0  0  H  z
; 2       F  L     0  0  0  .  0  0  0  .  0  0  0  H  z
; 3       H  2  .  4  %  1  0  0  L  0  .  4  %  1  0  0

.def counter_low          r0
.def counter_high         r1
.def counter_z            r2
.def freq_counter_low_lo  r3
.def freq_counter_low_hi  r4
.def freq_counter_high_lo r5
.def freq_counter_high_hi r6
.def freq_counter_rs_lo   r7
.def freq_counter_rs_hi   r8

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
	jmp interrupt_handler
.constants
start:
	mov r0, RAM_SIZE
	loadsp  r0
	mov r15, I2C_PORT
	call ssd1306_init
	call lcd_clear_screen

; line 0
	mov r15, CHAR_F
	clr r14 ; x
	clr r13 ; y
	call lcd_draw_char
	mov r15, CHAR_H
	inc r14 ; x
	call lcd_draw_char
	mov r14, 6
	mov r15, CHAR_PUNKT
	call lcd_draw_char
	mov r14, 10
	call lcd_draw_char
	mov r14, 13
	clr r15
	call lcd_draw_char
	inc r14
	mov r15, CHAR_H
	call lcd_draw_char
	inc r14
	mov r15, CHAR_z
	call lcd_draw_char
; line 1
	inc r13
	mov r15, CHAR_F
	clr r14 ; x
	call lcd_draw_char
	mov r14, 6
	mov r15, CHAR_PUNKT
	call lcd_draw_char
	mov r14, 10
	call lcd_draw_char
	mov r14, 13
	clr r15
	call lcd_draw_char
	inc r14
	mov r15, CHAR_H
	call lcd_draw_char
	inc r14
	mov r15, CHAR_z
	call lcd_draw_char
; line 2
	inc r13
	mov r15, CHAR_F
	clr r14 ; x
	call lcd_draw_char
	mov r15, CHAR_L
	inc r14 ; x
	call lcd_draw_char
	mov r14, 6
	mov r15, CHAR_PUNKT
	call lcd_draw_char
	mov r14, 10
	call lcd_draw_char
	mov r14, 13
	clr r15
	call lcd_draw_char
	inc r14
	mov r15, CHAR_H
	call lcd_draw_char
	inc r14
	mov r15, CHAR_z
	call lcd_draw_char
; line 3
	inc r13
	mov r15, CHAR_H
	clr r14 ; x
	call lcd_draw_char
	mov r14, 2
	mov r15, CHAR_PUNKT
	call lcd_draw_char
	mov r14, 10
	call lcd_draw_char
	mov r15, CHAR_PERCENT
	mov r14, 4
	call lcd_draw_char
	mov r14, 12
	call lcd_draw_char
	mov r15, CHAR_L
	mov r14, 8
	call lcd_draw_char

	mov r0, 4
	mov r1, DAC1_PORT
	out @r1, r0

	mov r0, 24
	mov r1, DAC2_PORT
	out @r1, r0

main_loop:
	wfi
	jmp main_loop

interrupt_handler:
	mov r15, LOGIC_PROBE_PORT
	in counter_low, @r15 ; counter_low
	inc r15
	in counter_high, @r15 ; counter_high
	inc r15
	in counter_z, @r15
	inc r15
	in freq_counter_low_lo, @r15
	inc r15
	in freq_counter_low_hi, @r15
	inc r15
	in freq_counter_high_lo, @r15
	inc r15
	in freq_counter_high_hi, @r15
	inc r15
	in freq_counter_rs_lo, @r15
	inc r15
	in freq_counter_rs_hi, @r15

	clr r9 ; y
	mov r10, freq_counter_high_lo
	mov r11, freq_counter_high_hi
	call show_frequency
	inc r9
	mov r10, freq_counter_rs_lo
	mov r11, freq_counter_rs_hi
	call show_frequency
	inc r9
	mov r10, freq_counter_low_lo
	mov r11, freq_counter_low_hi
	call show_frequency

	call lcd_update

	; interrupt_clear
	mov r15, I2C_PORT
	mov r0, 7
	out @r15, r0
	mov r0, 3
	out @r15, r0

	reti

show_frequency:
	push r9
	mov r12, 10
	call div3216
	mov r15, r13
	mov r14, 12
	mov r13, r9
	call draw_char_div
	dec r14
	call draw_char_div
	dec r14
	dec r14
	call draw_char_div
	dec r14
	call draw_char_div
	dec r14
	call draw_char_div
	dec r14
	dec r14
	call draw_char_div
	dec r14
	call draw_char_div
	dec r14
	call draw_char_div
	dec r14
	call lcd_draw_char
	pop r9
	ret

draw_char_div:
	push r13
	push r10
	push r11
	push r12
	call lcd_draw_char
	pop r12
	pop r11
	pop r10
	push r14
	call div3216
	pop r14
	mov r15, r13
	pop r13
	ret
