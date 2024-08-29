.include "lcd1.asmh"
.include "main.asmh"

jmp start
    reti
start:
    call DisplayControllerInit
    call ClearScreen
    mov lcd_char, 1
    mov lcd_x, 1 ; x
    mov lcd_y, 1 ; y
    clr inverted_colors
next:
    call CharacterOut
    inc lcd_char
    add lcd_x, 20
    add lcd_y, 20
    cmp lcd_y, 64
    jmplt next
    call LcdUpdate
    call DisplayOn
    hlt