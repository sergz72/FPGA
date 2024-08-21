.equ FREQUENCY_CODE_ADDRESS $2000
.equ DISPLAY_CONTROLLER_ADDRESS 0
.equ MCP3425_ADDRESS1 0
.equ MCP3425_ADDRESS2 0
.equ V_MUL 3125
.equ V_DIV 10000

.def frequency_code_address r64
.def frequency_code_lo r65
.def frequency_code_hi r66
.def display_controller_address r67

jmp start
    in frequency_code_lo, [frequency_code_address]
    in frequency_code_hi, [frequency_code_address+1]
    reti
start:
    mov frequency_code_address, FREQUENCY_CODE_ADDRESS
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
    mov rp, 46
    call save31
    call save3
    call save3
    ret
save3:
    dec rp
save31:
    mov r22, 3
save32:
    call div3216
    add r19, '0'
    mov @--rp, r19
    dec r22
    jmpnz save32
    ret

show_row:
    mov rp, 32
    mov r16, 16
show_row2:
    out [display_controller_address+1], @rp++
    dec r16
    jmpnz show_row2
    ret
