.segment code

; r0 - op1
; r1 - op2
; r2:r3 - result
mul1616:
    clr r2
    clr r3
mul1616_next2:
    test r1, 1
    beq mul1616_next
    add r2, r0
    adc r3, 0
mul1616_next:
    shl  r0
    rol  r64
    shr  r1
    bne mul1616_next2
    ret
