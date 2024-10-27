LED_ADDRESS = 0xF8000000

    lui t0, LED_ADDRESS >> 12
    lui t1, 0
loop:
    sw t1, 0(t0)
    addi t1, t1, 1
    j loop
