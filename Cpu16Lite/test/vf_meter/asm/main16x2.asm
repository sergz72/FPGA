.include "main16x2.asmh"

.def frequency_code_address r64
.def frequency_code_lo r65
.def frequency_code_hi r66
.def display_controller_address r67
.def timer_interrupt_clear_address r68
.def zero r69
.def one r70
.def current_channel r71

jmp start
    out [timer_interrupt_clear_address], one
    out [timer_interrupt_clear_address], zero
    reti
start:
    mov frequency_code_address, FREQUENCY_CODE_ADDRESS
    mov display_controller_address, DISPLAY_CONTROLLER_ADDRESS
    mov timer_interrupt_clear_address, TIMER_INTERRUPT_CLEAR_ADDRESS
    clr zero
    mov one, 1

    call hd_init
    call set_channel0

    ; the above code requires 2000 cpu ops
main_loop:
    ; about 5100 cpu operations
    ; with reserve ~20000 ops
    ; CPU clock should be about 100000 Hz
    hlt
    call prepare_adc_data
    test current_channel, current_channel
    jmpz to_freq_data
    mov r17, $C0 ; second row
    mov rp, 48
    call show_row

to_freq_data:
    in frequency_code_hi, [frequency_code_address+1]
    test frequency_code_hi, $8000
    jmpz change_channel
    in frequency_code_lo, [frequency_code_address]
    in frequency_code_hi, [frequency_code_address+1]
    and frequency_code_hi, $7FFF

    call prepare_freq_data
    mov r17, $80 ; first row
    mov rp, 32
    call show_row

change_channel:
    test current_channel, current_channel
    jmpz set_ch1
    call set_channel0
    jmp main_loop
set_ch1:
    call set_channel1    
    jmp main_loop

set_channel0:
    clr current_channel
    mov r17, MCP3426_CHANNEL0_CODE
set_channel:    
    mov r16, MCP3426_ADDRESS
    call i2c_master_write1
    ret

set_channel1:
    mov current_channel, 1
    mov r17, MCP3426_CHANNEL1_CODE
    jmp set_channel

prepare_adc_data:
    test current_channel, current_channel
    jmpz prepare_adc_data_channel0
    mov r61, 86 ; 'V'
    mov r62, 50 ; '2'
    mov r63, 52 ; '4'
    mov rp, 61
adc_get_save:
    mov r16, MCP3426_ADDRESS
    call get_adc_channel_data
    call save_adc_channel_data
    ret

prepare_adc_data_channel0:
    mov r54, 86 ; 'V'
    mov rp, 54
    jmp adc_get_save

save_adc_channel_data:
    mov r18, 10
    call save31
    mov @--rp, '.'
    mov r22, 2
    call save32
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
    mov r16, 16
    ; ddram address set command
    out [display_controller_address+DISPLAY_CONTROLLER_E], r17
    out [display_controller_address], r17
show_row2:
    out [display_controller_address+DISPLAY_CONTROLLER_RS+DISPLAY_CONTROLLER_E], @rp
    out [display_controller_address+DISPLAY_CONTROLLER_RS], @rp++
    dec r16
    jmpnz show_row2
    ret

hd_init:
    mov r17, $38 ; 2 rows
    out [display_controller_address+DISPLAY_CONTROLLER_E], r17
    out [display_controller_address], r17
    mov r16, 5 * DELAY_MS_OPS
    call delay
    out [display_controller_address+DISPLAY_CONTROLLER_E], r17
    out [display_controller_address], r17
    mov r16, 1 * DELAY_MS_OPS
    call delay
    out [display_controller_address+DISPLAY_CONTROLLER_E], r17
    out [display_controller_address], r17
    out [display_controller_address+DISPLAY_CONTROLLER_E], r17
    out [display_controller_address], r17
    mov r17, 1 ; clear display
    out [display_controller_address+DISPLAY_CONTROLLER_E], r17
    out [display_controller_address], r17
    mov r16, 2 * DELAY_MS_OPS
    call delay
;    mov r17, 6 ; entry mode address increment
;    out [display_controller_address+DISPLAY_CONTROLLER_E], r17
;    out [display_controller_address], r17
    mov r17, 9 ; display on
    out [display_controller_address+DISPLAY_CONTROLLER_E], r17
    out [display_controller_address], r17
    ret

delay:
    dec r16
    jmpnz delay
    ret
