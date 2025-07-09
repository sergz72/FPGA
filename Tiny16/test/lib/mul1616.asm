; r11 - op1
; r12 - op2
; r13:r14 - result
; r15 - work register
mul1616:
    clr r13
    clr r14
    clr r15
mul1616_next2:
    test r12, 1
    beq mul1616_next
    add r13, r11
    adc r14, r15
mul1616_next:
    shl  r11, r11
    rol  r15, r15
    shr  r12, r12
    bne mul1616_next2
    ret
