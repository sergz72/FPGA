DisplayOn:
    mov lcd_display_data, $3F
DisplayOn2:
    mov lcd_temp, KS0108_ADDRESS
    out [lcd_temp+KS0108_E], lcd_display_data
    out [lcd_temp], lcd_display_data
    ret

DisplayOff:
    mov lcd_display_data, $3E
    jmp DisplayOn2

LcdSetX:
    mov lcd_display_data, $B8
    or lcd_display_data, lcd_display_data, lcd_x
    out [lcd_temp+KS0108_E], lcd_display_data
    out [lcd_temp], lcd_display_data
    ret

LcdUpdate:
    mov lcd_temp, KS0108_ADDRESS

    mov lcd_display_data, $40 ; set y = 0
    out [lcd_temp+KS0108_E], lcd_display_data
    out [lcd_temp], lcd_display_data

    clr lcd_x
    call LcdSetX

    clr lcd_y
    mov lcd_p_ram_start, lcd_display_ram_address

LcdUpdateNextWord:
    mov lcd_p_ram, lcd_p_ram_start
LcdUpdateNext:
    in lcd_display_data, [lcd_p_ram]
    call LcdUpdateChip
    inc lcd_y
    add lcd_p_ram, 8
    cmp lcd_y, 64
    jmplt LcdUpdateNext

    clr lcd_y
    inc lcd_x
    mov lcd_p_ram, lcd_p_ram_start
    call LcdSetX

LcdUpdateNext2:
    in lcd_display_data, [lcd_p_ram]
    shr lcd_display_data, 8
    call LcdUpdateChip
    inc lcd_y
    add lcd_p_ram, 8
    cmp lcd_y, 64
    jmplt LcdUpdateNext2

    clr lcd_y
    inc lcd_x
    inc lcd_p_ram_start
    call LcdSetX

    cmp lcd_x, 16
    jmplt LcdUpdateNextWord

    ret

LcdUpdateChip:
    test lcd_x, 8
    jmpne LcdUpdateChip2
    out [lcd_temp+KS0108_CS2+KS0108_DC+KS0108_E], lcd_display_data
    out [lcd_temp+KS0108_CS2+KS0108_DC], lcd_display_data
    ret
LcdUpdateChip2:
    out [lcd_temp+KS0108_CS1+KS0108_DC+KS0108_E], lcd_display_data
    out [lcd_temp+KS0108_CS1+KS0108_DC], lcd_display_data
    ret