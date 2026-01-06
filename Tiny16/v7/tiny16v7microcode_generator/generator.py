position = 1

def allocate_bit(n):
    global position
    rc = position
    position <<= n
    return rc

MICROCODE_SIZE = 512
OPCODE_SIZE = 8

STAGE_RESET = allocate_bit(1)
ERROR = allocate_bit(1)
HALT  = allocate_bit(1)
WAIT  = allocate_bit(1)

SRC_ADDR_SOURCE = allocate_bit(2)
SRC_ADDR_SOURCE_NEXT = SRC_ADDR_SOURCE
SRC_ADDR_SOURCE_SAVED = 2 * SRC_ADDR_SOURCE
SRC_ADDR_SOURCE_IMMEDIATE = 3 * SRC_ADDR_SOURCE

PC_ADDR_SOURCE = allocate_bit(2)
PC_SOURCE_NEXT = PC_ADDR_SOURCE
PC_SOURCE_SAVED = 2 * PC_ADDR_SOURCE
PC_SOURCE_IMMEDIATE = 3 * PC_ADDR_SOURCE

REGISTERS_WR = allocate_bit(1)
REGISTERS_WR_SOURCE = allocate_bit(2)
REGISTERS_WR_SOURCE_OP1 = REGISTERS_WR_SOURCE
REGISTERS_WR_SOURCE_SRC = 2 * REGISTERS_WR_SOURCE

RAM_WR = allocate_bit(1)
MEM_VALID = allocate_bit(1)
NWR = allocate_bit(1)

NEXT = SRC_ADDR_SOURCE_NEXT | PC_SOURCE_NEXT

microcode = [ERROR] * MICROCODE_SIZE

def generate_halt(opcode):
    start = opcode * OPCODE_SIZE
    microcode[start] = 0
    microcode[start+1] = HALT|NEXT

def generate_wait(opcode):
    start = opcode * OPCODE_SIZE
    microcode[start] = 0
    microcode[start+1] = WAIT|NEXT|STAGE_RESET

def generate_alu1(opcode):
    start = opcode * OPCODE_SIZE
    for i in range(0, 4):
        microcode[start] = 0
        microcode[start+1] = NEXT
        microcode[start+2] = 0
        microcode[start+3] = REGISTERS_WR | REGISTERS_WR_SOURCE_OP1 | NEXT | STAGE_RESET
        start += 8

def generate_alu2rr(opcode):
    start = opcode * OPCODE_SIZE
    for i in range(0, 4):
        microcode[start] = 0
        microcode[start+1] = NEXT
        microcode[start+2] = 0
        microcode[start+3] = NEXT
        microcode[start+4] = NEXT | STAGE_RESET
        if (i != 3):
            microcode[start+4] |= REGISTERS_WR | REGISTERS_WR_SOURCE_SRC
        start += 8

def generate_alu2ri8(opcode):
    start = opcode * OPCODE_SIZE
    for i in range(0, 4):
        microcode[start] = 0
        microcode[start+1] = NEXT
        microcode[start+2] = NEXT
        microcode[start+4] = NEXT | STAGE_RESET
        if (i != 3):
            microcode[start+4] |= REGISTERS_WR | REGISTERS_WR_SOURCE_SRC
        start += 8

def generate_alu2ri16(opcode):
    start = opcode * OPCODE_SIZE
    for i in range(0, 4):
        microcode[start] = 0
        microcode[start+1] = NEXT
        microcode[start+2] = NEXT
        microcode[start+3] = NEXT
        microcode[start+4] = NEXT | STAGE_RESET
        if (i != 3):
            microcode[start+4] |= REGISTERS_WR | REGISTERS_WR_SOURCE_SRC
        start += 8

def generate_br(opcode):
    start = opcode * OPCODE_SIZE
    for i in range(0, 4):
        microcode[start] = 0
        microcode[start+1] = ERROR
        start += 8

def generate_call(opcode):
    start = opcode * OPCODE_SIZE
    microcode[start] = 0
    microcode[start+1] = ERROR

def generate_jmp(opcode):
    start = opcode * OPCODE_SIZE
    microcode[start] = 0
    microcode[start+1] = ERROR

def generate_in(opcode):
    start = opcode * OPCODE_SIZE
    microcode[start] = 0
    microcode[start+1] = ERROR

def generate_out(opcode):
    start = opcode * OPCODE_SIZE
    microcode[start] = 0
    microcode[start+1] = ERROR

def generate_lb(opcode):
    start = opcode * OPCODE_SIZE
    microcode[start] = 0
    microcode[start+1] = ERROR

def generate_lw(opcode):
    start = opcode * OPCODE_SIZE
    microcode[start] = 0
    microcode[start+1] = ERROR

def generate_sb(opcode):
    start = opcode * OPCODE_SIZE
    microcode[start] = 0
    microcode[start+1] = ERROR

def generate_sw(opcode):
    start = opcode * OPCODE_SIZE
    microcode[start] = 0
    microcode[start+1] = ERROR

def generate_rcall(opcode):
    start = opcode * OPCODE_SIZE
    microcode[start] = 0
    microcode[start+1] = ERROR

def generate_rjmp(opcode):
    start = opcode * OPCODE_SIZE
    microcode[start] = 0
    microcode[start+1] = ERROR

def generate_ret(opcode):
    start = opcode * OPCODE_SIZE
    microcode[start] = 0
    microcode[start+1] = ERROR

def generate_reti(opcode):
    start = opcode * OPCODE_SIZE
    microcode[start] = 0
    microcode[start+1] = ERROR

def print_microcode():
    for i in range(0, MICROCODE_SIZE):
        print("%07X" % microcode[i])

# one byte instructions
generate_halt(0)
generate_wait(1)
generate_ret(2)
generate_reti(3)

# load/store instructions - 3 byte
generate_lb(18)
generate_lw(19)
generate_sb(20)
generate_sw(21)

# in/out instructions - 3 byte
generate_in(22)
generate_out(23)

# rcall/rjmp instructions - 2 byte
generate_rcall(24)
generate_rjmp(25)

# call/jmp instructions - 3 byte
generate_call(26)
generate_jmp(27)

# branch instructions - 2 byte
generate_br(28)

# alu two byte instructions
generate_alu1(32)

# alu instructions - 3 byte
generate_alu2rr(36)
generate_alu2ri8(44)

# alu instructions - 4 byte
generate_alu2ri16(52)

print_microcode()
