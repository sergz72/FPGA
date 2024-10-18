; display width = 128
; display height = 64
.equ DISPLAY_RAM_SIZE $200
.equ DISPLAY_RAM_END DISPLAY_RAM_START + DISPLAY_RAM_SIZE - 1
.equ LCD_LINE_WIDTH_BITS 3 ; 8 16 bit words
.equ LCD_LINE_WIDTH 8 ; 16 bit words

.def lcd_character_ram_address r0
.def lcd_display_ram_address r1
.def lcd_display_ram_end r2
.def lcd_character_count r3
.def lcd_font_width r4
.def lcd_font_height r5
.def lcd_line_width r6
.def lcd_font_mask r7

.def lcd_mask r16
.def lcd_temp r17
.def lcd_h r18
.def lcd_p_font_rom r19
.def lcd_p_ram_start r20
.def lcd_p_ram r21
.def lcd_font_data r22
.def lcd_display_data r23
.def lcd_offset r24
.def lcd_end r25
.def lcd_bits r26

DisplayControllerInit:
    mov lcd_character_ram_address, CHARACTER_RAM_START
    mov lcd_display_ram_address, DISPLAY_RAM_START
    mov lcd_display_ram_end, DISPLAY_RAM_END
    in  lcd_font_width, [lcd_character_ram_address]
    in  lcd_font_height, [lcd_character_ram_address+1]
    in  lcd_character_count, [lcd_character_ram_address+2]
    ser lcd_font_mask
    mov lcd_temp, 16
    sub lcd_temp, lcd_temp, lcd_font_width
    shr lcd_font_mask, lcd_font_mask, lcd_temp
    mov lcd_line_width, LCD_LINE_WIDTH
    ret

ClearScreen:
    mov lcd_p_ram, lcd_display_ram_address
    clr lcd_temp
ClearScreenNext:
    out [lcd_p_ram], lcd_temp
    inc lcd_p_ram
    cmp lcd_p_ram, lcd_display_ram_end
    jmple ClearScreenNext
    ret

CharacterOut:
    cmp lcd_char, lcd_character_count
    ; if char >= character_count
    retge

    mov r16, lcd_char
    mov r17, lcd_font_height
    call mul1616
    mov lcd_p_font_rom, r18+3
    add lcd_p_font_rom, lcd_p_font_rom, lcd_character_ram_address
    
    mov lcd_h, lcd_font_height

    mov lcd_p_ram_start, lcd_y
    shl lcd_p_ram_start, LCD_LINE_WIDTH_BITS
    add lcd_p_ram_start, lcd_p_ram_start, lcd_display_ram_address

CharacterOutNextRow:
    cmp lcd_p_ram_start, lcd_display_ram_end
    retgt
    test lcd_h, lcd_h
    retz

    add lcd_end, lcd_p_ram_start, lcd_line_width
    
    mov lcd_p_ram, lcd_x
    shr lcd_p_ram, 4
    add lcd_p_ram, lcd_p_ram, lcd_p_ram_start

    cmp lcd_p_ram, lcd_end
    retge

    in lcd_font_data, [lcd_p_font_rom]

    test inverted_colors, inverted_colors
    jmpz CharacterOutNotInvertedColors
    not lcd_font_data
    and lcd_font_data, lcd_font_data, lcd_font_mask
CharacterOutNotInvertedColors:

    in lcd_display_data, [lcd_p_ram]

    mov lcd_offset, lcd_x
    and lcd_offset, $000F
    
    mov lcd_bits, 16
    sub lcd_bits, lcd_bits, lcd_offset

    shl lcd_temp, lcd_font_data, lcd_offset

    shl lcd_mask, lcd_font_mask, lcd_offset

    and lcd_temp, lcd_temp, lcd_mask

    not lcd_mask
    and lcd_display_data, lcd_display_data, lcd_mask
    or lcd_display_data, lcd_display_data, lcd_temp

    out [lcd_p_ram], lcd_display_data

    cmp lcd_bits, lcd_font_width
    jmpge CharacterOutSkipWord2

    inc lcd_p_ram
    cmp lcd_p_ram, lcd_end
    jmpge CharacterOutSkipWord2

    in lcd_display_data, [lcd_p_ram]

    shr lcd_temp, lcd_font_data, lcd_bits
    shr lcd_mask, lcd_font_mask, lcd_bits

    not lcd_mask
    and lcd_display_data, lcd_display_data, lcd_mask
    or lcd_display_data, lcd_display_data, lcd_temp

    out [lcd_p_ram], lcd_display_data

CharacterOutSkipWord2:
    add lcd_p_ram_start, LCD_LINE_WIDTH
    inc lcd_p_font_rom
    dec lcd_h
    jmp CharacterOutNextRow
