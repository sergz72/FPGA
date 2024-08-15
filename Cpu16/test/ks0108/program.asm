.def font_width r0
.def font_height r1
.def space_lines r2
.def char r3
.def display_ram_pointer r4
.def flags r5
.def all_lines r6
.def character_ram_pointer r3
.def pixel_data r7
.def offset r8
.def mask r9
.def display_data r10
.def font_mask r11
.def current_width r12

CharacterOut:
    cmp char, character_ram, 3 ; character count
    bge CharacterOutError
    mov font_width, character_ram, 0
    mov font_mask, 0xFFFF
    sub mask, 16, font_width
    shr font_mask, font_mask, mask
    mov font_height, character_ram, 1
    mov space_lines, character_ram, 2
    add all_lines, font_height, space_lines
    mul char, char, all_lines
    add char, char, 4
    ; r3 now is character ram pointer
    mov current_width, font_width
    mov pixel_data, character_ram, character_ram_pointer
    and offset, x, 7
    shl pixel_data, pixel_data, offset
    shl font_mask, font_mask, offset
    mov mask, 0xFF
    sub offset, 8, offset
    shl mask, mask, offset
    not mask
CharacterOutNextByte:
    cmp display_ram_pointer, DISPLAY_RAM_END
    bgt CharacterOutEnd
    mov display_data, display_ram, display_ram_pointer
    and display_data, display_data, mask
    or display_data, display_data, pixel_data
    mov display_ram, display_ram_pointer, display_data
    inc display_ram_pointer
    shr pixel_data, pixel_data, 8
    shr font_mask, font_mask, 8
    cmp current_width, 8
    ble CharacterOutNextLine
    sub current_width, current_width, 8
    jmp CharacterOutNextByte
CharacterOutNextLine:
    add display_ram_pointer,    
CharacterOutError:
CharacterOutEnd:
    ret
