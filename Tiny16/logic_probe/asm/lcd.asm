; char in r15
; x_pos in r14
; y_pos in r13
; r9, r10, r11, r12 - temporary data
lcd_draw_char:
    mov r12, r13
    shl r12, r12
    shl r12, r12
    shl r12, r12
    shl r12, r12
    add r12, r14 ; +x
    shl r12, r12
    shl r12, r12
    shl r12, r12 ; y*128+x*8
    lda r11, lcd_buffer
    add r12, r11 ; buffer pointer
    mov r10, r15
    shl r10, r10
    shl r10, r10
    shl r10, r10 ; char*8
    lda r11, font8
    add r11, r10 ; char pointer
    mov r9, FONT_WIDTH
lcd_draw_char_next:
    mov r10, @r11
    mov @r12, r10
    inc r11
    inc r12
    dec r9
    bne lcd_draw_char_next
    ret
