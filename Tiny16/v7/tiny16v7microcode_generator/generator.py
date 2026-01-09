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

SRC_ADDR_SOURCE = allocate_bit(3)
SRC_ADDR_SOURCE_NEXT = SRC_ADDR_SOURCE
SRC_ADDR_SOURCE_SAVED = 2 * SRC_ADDR_SOURCE
SRC_ADDR_SOURCE_IMMEDIATE = 3 * SRC_ADDR_SOURCE
SRC_ADDR_SOURCE_BR = 4 * SRC_ADDR_SOURCE
SRC_ADDR_SOURCE_REGISTER = 5 * SRC_ADDR_SOURCE

PC_ADDR_SOURCE = allocate_bit(3)
PC_SOURCE_NEXT = PC_ADDR_SOURCE
PC_SOURCE_SAVED = 2 * PC_ADDR_SOURCE
PC_SOURCE_IMMEDIATE = 3 * PC_ADDR_SOURCE
PC_SOURCE_BR = 4 * PC_ADDR_SOURCE

REGISTERS_WR = allocate_bit(1)
REGISTERS_WR_SOURCE = allocate_bit(2)
REGISTERS_WR_SOURCE_OP1 = REGISTERS_WR_SOURCE
REGISTERS_WR_SOURCE_SRC = 2 * REGISTERS_WR_SOURCE
REGISTERS_WR_SOURCE_OP2 = 3 * REGISTERS_WR_SOURCE

RAM_WR = allocate_bit(1)
MEM_VALID = allocate_bit(1)
NWR = allocate_bit(1)
IO = allocate_bit(1)
ALU_CLK = allocate_bit(1)

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
        microcode[start+3] = REGISTERS_WR | REGISTERS_WR_SOURCE_OP1 | NEXT | STAGE_RESET | ALU_CLK
        start += 8

def generate_alu2rr(opcode):
    start = opcode * OPCODE_SIZE
    for i in range(0, 4):
        microcode[start] = 0
        microcode[start+1] = NEXT
        microcode[start+2] = 0
        microcode[start+3] = NEXT
        microcode[start+4] = NEXT | STAGE_RESET | ALU_CLK
        if (i != 3):
            microcode[start+4] |= REGISTERS_WR | REGISTERS_WR_SOURCE_SRC
        start += 8

def generate_alu2ri8(opcode):
    start = opcode * OPCODE_SIZE
    for i in range(0, 4):
        microcode[start] = 0
        microcode[start+1] = NEXT
        microcode[start+2] = NEXT
        microcode[start+3] = NEXT | STAGE_RESET | ALU_CLK
        if (i != 3):
            microcode[start+3] |= REGISTERS_WR | REGISTERS_WR_SOURCE_SRC
        start += 8

def generate_alu2ri16(opcode):
    start = opcode * OPCODE_SIZE
    for i in range(0, 4):
        microcode[start] = 0
        microcode[start+1] = NEXT
        microcode[start+2] = NEXT
        microcode[start+3] = NEXT
        microcode[start+4] = NEXT | STAGE_RESET | ALU_CLK
        if (i != 3):
            microcode[start+4] |= REGISTERS_WR | REGISTERS_WR_SOURCE_OP2
        start += 8

def generate_br(opcode):
    start = opcode * OPCODE_SIZE
    for i in range(0, 4):
        microcode[start] = 0
        microcode[start+1] = NEXT
        microcode[start+2] = PC_SOURCE_BR | SRC_ADDR_SOURCE_BR | STAGE_RESET
        start += 8

def generate_call(opcode):
    start = opcode * OPCODE_SIZE
    microcode[start] = 0
    microcode[start+1] = ERROR

def generate_jmp(opcode):
    start = opcode * OPCODE_SIZE
    microcode[start] = 0
    microcode[start+1] = NEXT
    microcode[start+2] = NEXT
    microcode[start+3] = PC_SOURCE_IMMEDIATE | SRC_ADDR_SOURCE_IMMEDIATE | STAGE_RESET

def generate_in(opcode):
    start = opcode * OPCODE_SIZE
    microcode[start] = 0
    microcode[start+1] = NEXT | NWR
    microcode[start+2] = NEXT | IO | NWR
    microcode[start+3] = NEXT | MEM_VALID | NWR
    microcode[start+4] = STAGE_RESET | NWR | REGISTERS_WR | REGISTERS_WR_SOURCE_OP2 | ALU_CLK

def generate_out(opcode):
    start = opcode * OPCODE_SIZE
    microcode[start] = 0
    microcode[start+1] = NEXT
    microcode[start+2] = IO
    microcode[start+3] = NEXT | MEM_VALID
    microcode[start+4] = STAGE_RESET

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
    microcode[start+1] = PC_SOURCE_SAVED | SRC_ADDR_SOURCE_SAVED | STAGE_RESET

def print_microcode():
    for i in range(0, MICROCODE_SIZE):
        print("%07X // %03X.%d" % (microcode[i], i >> 3, i % 8))

# one byte instructions
generate_halt(0)
generate_wait(1)

# in instruction - 3 byte
generate_in(2)

generate_ret(3)
generate_reti(4)

# load/store instructions - 3 byte
generate_lb(0x12)
generate_lw(0x13)
generate_sb(0x14)
generate_sw(0x15)

# out instruction - 3 byte
generate_out(0x17)
# rcall/rjmp instructions - 2 byte
generate_rcall(0x18)
generate_rjmp(0x19)

# call/jmp instructions - 3 byte
generate_call(0x1A)
generate_jmp(0x1B)

# branch instructions - 2 byte
generate_br(0x1C)

# alu two byte instructions
# 1000XX
generate_alu1(0x20)

# alu instructions - 3 byte
# 1001XX
generate_alu2rr(0x24)
# 1011XX
generate_alu2ri8(0x2C)

# alu instructions - 4 byte
# 1101XX
generate_alu2ri16(0x34)

print_microcode()
