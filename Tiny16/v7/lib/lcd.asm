function lcd_draw_char(char:16,x_pos:16,y_pos:16)
locals buffer_pointer:16, char_pointer:16, counter:16, temp:16
    mov buffer_pointer, y_pos
    shl buffer_pointer
    shl buffer_pointer
    shl buffer_pointer
    shl buffer_pointer
    add buffer_pointer, x_pos ; +x
    shl buffer_pointer
    shl buffer_pointer
    shl buffer_pointer ; y*128+x*8
    adda buffer_pointer, lcd_buffer
    mov char_pointer, char
    shl char_pointer
    shl char_pointer
    shl char_pointer ; char*8
    adda char_pointer, font8
    mov counter, FONT_WIDTH
lcd_draw_char_next:
    lb temp, @char_pointer
    sb @buffer_pointer, temp
    inc char_pointer
    inc buffer_pointer
    dec counter
    bne lcd_draw_char_next
    return
endfunction
