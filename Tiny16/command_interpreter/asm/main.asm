.equ cmd_buffer_size 100
.equ led_address $F000
.equ timer_address $C000
.equ delay 100000 / 2

; variables
.var cmd_buffer_p
.var command_ready
.var led_state
.var timer_interrupt

.segment code

	j start
	j uart_isr
	j timer_isr
uart_data_address:
	dw $E000
cmd_buffer_address:
	dw cmd_buffer

timer_isr:
	sw A, -1(SP)
	lli A, 1
	sw A, timer_interrupt
	lw A, -1(SP)
	reti

uart_isr:
	sw A, -1(SP)
	sw W, -2(SP)
	sw X, -3(SP)

; check that command is processed
	lw A, command_ready
	and A, A
	bnz isr_done

; read symbol
	lw X, uart_data_address
	lw A, 0(X)

;check that we haven't reached end of the command buffer 
	lw W, cmd_buffer_p
	la X, cmd_buffer_end
	cmp W, X
	bge check_cr

; store symbol to the command buffer
	sw A, 0(W)

; inc command buffer_p
	lli X, 1
	add W, X
	sw W, cmd_buffer_p

; echo symbol
	lw X, uart_data_address
	sw A, 0(X)

check_cr:
; check that symbol is '\r'
	lli W, '\r'
	cmp A, W
	bne isr_done

; echo '\n'
	lli A, '\n'
	sw A, 0(X)

; set command_ready
	lli A, 1
	sw A, command_ready

isr_done:
	lw A, -1(SP)
	lw W, -2(SP)
	lw X, -3(SP)
	reti

start:
	lli SP, $FF00
	lw A, cmd_buffer_address
	sw A, cmd_buffer_p
	lli A, 0
	sw A, command_ready

	sw  A, led_state

next:
; delay
	li A, delay
	li W, timer_address
	sw A, 0(W)
not_timer_interrupt:
	wfi
	lw A, timer_interrupt
	and A, A
	beq not_timer_interrupt
	
	clr A
	sw A, timer_interrupt

; toggle led
	li X, led_address
	lw A, led_state
	lli W, 1
	xor A, W
	sw A, 0(X)
	sw A, led_state

; check cmd is ready
	lw A, command_ready
	and A, A
	beq next
; todo - command processing
	lw A, cmd_buffer_address
	sw A, cmd_buffer_p
	lli A, 0
	sw A, command_ready
	j next

.segment bss
cmd_buffer:
	resw cmd_buffer_size - 1
cmd_buffer_end:
	resw 1
