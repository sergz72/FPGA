; display width = 128
; display height = 64
.equ DISPLAY_RAM_SIZE $1FF
.equ DISPLAY_RAM_START $8000
.equ DISPLAY_RAM_END DISPLAY_RAM_START + DISPLAY_RAM_SIZE
.equ CHARACTER_RAM_START $6000
.equ LINE_WIDTH 8 ; 16 bit words

.def character_ram_address r0
.def display_ram_address r1
.def display_ram_end r2
.def character_count r3
.def font_width r4
.def font_height r5

.def flags r6
.def display_data r7

.def temp r32
.def mask r33
.def font_mask r34
.def current_width r35
.def offset r36
.def pixel_data r37
.def display_ram_pointer r38
.def temp_font_mask r39

.def character_ram_pointer r51

DisplayControllerInit:
    mov character_ram_address, CHARACTER_RAM_START
    mov display_ram_address, DISPLAY_RAM_START
    mov display_ram_end, DISPLAY_RAM_END
    in  font_width, [character_ram_address]
    in  font_height, [character_ram_address+1]
    in  character_count, [character_ram_address+2]
    ser font_mask
    mov temp, 16
    sub mask, temp, font_width
    shr font_mask, font_mask, mask
    ret

CharacterOut:
    cmp char, character_count
    ; if char >= character_count
    retge
    mov r16, char
    mov r17, font_height
    call mul1616
    mov character_ram_pointer, r18+3
    add character_ram_pointer, character_ram_pointer, character_ram_address
    mov current_width, font_width
    in pixel_data, [character_ram_pointer]
    mov offset, x
    and offset, $F
    shl pixel_data, pixel_data, offset
    shl temp_font_mask, font_mask, offset
    not temp_font_mask
    and pixel_data, pixel_data, temp_font_mask

    mov mask, $FF
    mov temp, 8
    sub offset, temp, offset
    shl mask, mask, offset
    not mask

    shr x, 4
    mov r16, y
    mov r17, LINE_WIDTH
    call mul1616
    add display_ram_pointer, r16, display_ram_address

CharacterOutNextWord:
    cmp display_ram_pointer, display_ram_end
    retgt
    in temp, [display_ram_pointer]
    and temp, display_data, mask
    or temp, display_data, pixel_data
    out [display_ram_pointer], temp
    inc display_ram_pointer
    shr pixel_data, 8
    shr font_mask, 8
    cmp current_width, 8
    jmple CharacterOutNextLine
    sub current_width, 8
    jmp CharacterOutNextWord
CharacterOutNextLine:
    add display_ram_pointer, LINE_WIDTH
    jmp CharacterOutNextWord
