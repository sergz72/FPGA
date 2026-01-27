.segment code

;------
; FUNCTION DEF: Div
; DESCRIPTION:  unsigned 32/16 division, R11|R10 / R12 = R11:R10, Remainder in R13
; REGISTER USE: R50 is dividend low word and result low word
;               R51 is dividend high word and result high word
;               R52 is divisor
;               R53 is remainder
;               R64 is working register
;               R65 is counter
;------
; Step-1: First the registers are initialized with corresponding values (Q = Dividend, M = Divisor, A = 0, n = number of bits in dividend)
div3216:    		clr   R53
			mov   R65, 32
; Step-2: Then the content of register A and Q is shifted left as if they are a single unit
div_l2:			shl  R50
			rol  R51
			rol  R53
; Step-3: Then content of register M is subtracted from A and result is stored in C
			mov   R64, R53
			sub   R64, R52
; Step-4: Then the most significant bit of the C is checked if it is 0 the least significant bit of Q is set to 1 and A = C otherwise
; if it is 1 the least significant bit of Q is set to 0
			bmi  div_l1
			or    R50, 1
			mov   R53, R64
; Step-5: The value of counter n is decremented. If the value of n becomes zero we get of the loop otherwise we repeat from step 2
div_l1:			dec   R65
; Finally, the register Q contain the quotient and A contain remainder
			bne  div_l2
			ret
