; r16 - op1
; r17 - op2
; r18:r19 - result
; r20 - work register
mul1616:
    test r16, r16
    retz
    clr r18
    clr r19
    clr r20
mul1616_next2:
    test r17, 1
    jmpz mul1616_next
    add r18, r18, r16
    adc r19, r19, r20
mul1616_next:
    shlc r16, r16
    rlc  r20, r20
    shr  r17, 1
    jmpnz mul1616_next2
    ret
