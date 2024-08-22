;------
; FUNCTION DEF: Div
; DESCRIPTION:  unsigned 32/16 division, R17|R16 / R18 = R17:R16, Remainder in R19
; REGISTER USE: R17 is dividend high word and result high word
;               R16 is dividend low word and result low word
;               R18 is divisor
;               R19 is remainder
;               R20 is working register
;               R21 is counter
;------
; Step-1: First the registers are initialized with corresponding values (Q = Dividend, M = Divisor, A = 0, n = number of bits in dividend)
div3216:        clr     R19
                mov     R21, 32
; Step-2: Then the content of register A and Q is shifted left as if they are a single unit
div_l2:		shlc    R16, R16
		rlc     R17, R17
		rlc	R19, R19
; Step-3: Then content of register M is subtracted from A and result is stored in C
		sub     R20, R19, R18
; Step-4: Then the most significant bit of the C is checked if it is 0 the least significant bit of Q is set to 1 and A = C otherwise
; if it is 1 the least significant bit of Q is set to 0
		test	R20, $8000
		jmpnz   div_l1
		or      R16, 1
		mov     R19, R20
; Step-5: The value of counter n is decremented. If the value of n becomes zero we get of the loop otherwise we repeat from step 2
div_l1:		dec     R21
; Finally, the register Q contain the quotient and A contain remainder
		retz
		jmp     div_l2
