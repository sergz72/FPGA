;------
; FUNCTION DEF: Div
; DESCRIPTION:  unsigned 32/16 division, R11|R10 / R12 = R11:R10, Remainder in R13
; REGISTER USE: R10 is dividend low word and result low word
;               R11 is dividend high word and result high word
;               R12 is divisor
;               R13 is remainder
;               R14 is working register
;               R15 is counter
;------
; Step-1: First the registers are initialized with corresponding values (Q = Dividend, M = Divisor, A = 0, n = number of bits in dividend)
div3216:    		clr   R13
			mov   R15, 32
; Step-2: Then the content of register A and Q is shifted left as if they are a single unit
div_l2:			shl  R10, R10
			rol  R11, R11
			rol  R13, R13
; Step-3: Then content of register M is subtracted from A and result is stored in C
			mov   R14, R13
			sub   R14, R12
; Step-4: Then the most significant bit of the C is checked if it is 0 the least significant bit of Q is set to 1 and A = C otherwise
; if it is 1 the least significant bit of Q is set to 0
			bmi  div_l1
			or    R10, 1
			mov   R13, R14
; Step-5: The value of counter n is decremented. If the value of n becomes zero we get of the loop otherwise we repeat from step 2
div_l1:			dec   R15
; Finally, the register Q contain the quotient and A contain remainder
			bne  div_l2
			ret
