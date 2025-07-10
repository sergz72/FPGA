; char in r15
; x_pos in r14
; y_pos in r13
lcd_draw_char:
    shl r13, r13
    shl r13, r13
    shl r13, r13
    shl r13, r13
    add r13, r14 ; +x
    shl r13, r13
    shl r13, r13
    shl r13, r13 ; y*128+x*8
    lda r12, lcd_buffer
    add r12, r13 ; buffer pointer
    shl r15, r15
    shl r15, r15
    shl r15, r15 ; char*8
    lda r11, font8
    add r11, r15 ; char pointer
    mov r13, FONT_WIDTH
lcd_draw_char_next:
    mov r14, @r11
    mov @r12, r14
    inc r11
    inc r12
    dec r13
    bne lcd_draw_char_next
    ret
