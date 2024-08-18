.equ FREQUENCY_CODE_LO_ADDRESS $2000
.equ FREQUENCY_CODE_HI_ADDRESS $2001
.equ DISPLAY_CONTROLLER_ADDRESS 0
.equ MCP3425_ADDRESS1 0
.equ MCP3425_ADDRESS2 0
.equ V_MUL 3125
.equ V_DIV 10000

.def frequency_code_lo_address r64
.def frequency_code_hi_address r65
.def frequency_code_lo r66
.def frequency_code_hi r67
.def display_controller_address r68

jmp start
    in frequency_code_lo, [frequency_code_lo_address]
    in frequency_code_hi, [frequency_code_hi_address]
    reti
start:
    mov frequency_code_lo_address, FREQUENCY_CODE_LO_ADDRESS
    mov frequency_code_hi_address, FREQUENCY_CODE_HI_ADDRESS
    mov display_controller_address, DISPLAY_CONTROLLER_ADDRESS

    mov r17, $88
    mov r16, MCP3425_ADDRESS1
    call i2c_master_write1
    mov r17, $88
    mov r16, MCP3425_ADDRESS2
    call i2c_master_write1

main_loop:
    hlt
    call prepare_freq_data
    call show_row
    call prepare_adc_data
    call show_row
    jmp main_loop

prepare_adc_data:
    mov r16, MCP3425_ADDRESS1
    call get_adc_channel_data
    mov r16, MCP3425_ADDRESS2
    call get_adc_channel_data

    mov r38, 86 ; 'V'
    mov r45, 86 ; 'V'
    mov r46, 50 ; '2'
    mov r47, 52 ; '4'

    ret

get_adc_channel_data:
    call i2c_master_read2
    mov r16, V_MUL
    call mul1616
    mov r16, r18
    mov r17, r19
    mov r18, V_DIV
    call div3216
    ret

prepare_freq_data:
    mov r46, 72 ; 'H'
    mov r47, 122 ; 'z'
    mov r42, 46 ; .
    mov r38, 46 ; .
    mov r34, 32 ; space
    mov r33, 32 ; space
    mov r32, 32 ; space

    mov r18, 10
    mov r17, frequency_code_hi
    mov r16, frequency_code_lo
    call div3216
    mov r45, r19
    add r45, '0'
    call div3216
    mov r44, r19
    add r44, 48 ; '0'
    call div3216
    mov r43, r19
    add r43, 48 ; '0'
    call div3216
    mov r41, r19
    add r41, 48 ; '0'
    call div3216
    mov r40, r19
    add r40, 48 ; '0'
    call div3216
    mov r39, r19
    add r39, 48 ; '0'
    call div3216
    mov r37, r19
    add r37, 48 ; '0'
    call div3216
    mov r36, r19
    add r36, 48 ; '0'
    call div3216
    mov r35, r19
    add r35, 48 ; '0'
    ret

show_row:
    out [display_controller_address+1], r32
    out [display_controller_address], r33
    out [display_controller_address], r34
    out [display_controller_address], r35
    out [display_controller_address], r36
    out [display_controller_address], r37
    out [display_controller_address], r38
    out [display_controller_address], r39
    out [display_controller_address], r40
    out [display_controller_address], r41
    out [display_controller_address], r42
    out [display_controller_address], r43
    out [display_controller_address], r44
    out [display_controller_address], r45
    out [display_controller_address], r46
    out [display_controller_address], r47
    ret
