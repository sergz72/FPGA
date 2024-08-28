.include "lcd1.asmh"

jmp start
    reti
start:
    call DisplayControllerInit
    mov char, '1'
    mov x, 1 ; x
    mov y, 1 ; y
next:
    call CharacterOut
    inc char
    add x, 20
    add y, 20
    cmp y, 64
    jmplt next
    hlt