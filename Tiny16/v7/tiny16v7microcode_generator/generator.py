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

ALU_OP = allocate_bit(5)
ALU_OP_ADC  = ALU_OP
ALU_OP_ADD  = 2 * ALU_OP
ALU_OP_SBC  = 3 * ALU_OP
ALU_OP_SUB  = 4 * ALU_OP
ALU_OP_CMP  = 5 * ALU_OP
ALU_OP_AND  = 6 * ALU_OP
ALU_OP_TEST = 7 * ALU_OP
ALU_OP_OR   = 8 * ALU_OP
ALU_OP_XOR  = 9 * ALU_OP
ALU_OP_SHL  = 10 * ALU_OP
ALU_OP_SHR  = 11 * ALU_OP
ALU_OP_ROL  = 12 * ALU_OP
ALU_OP_ROR  = 13 * ALU_OP
ALU_OP_MOV  = 14 * ALU_OP
ALU_OP_CLR  = 15 * ALU_OP
ALU_OP_SET  = 16 * ALU_OP
ALU_OP_INC  = 17 * ALU_OP
ALU_OP_DEC  = 18 * ALU_OP
ALU_OP_NOT  = 19 * ALU_OP
ALU_OP_NEG  = 20 * ALU_OP

REGISTERS_WR = allocate_bit(1)
REGISTERS_WR_SOURCE = allocate_bit(2)
REGISTERS_WR_SOURCE_OP1 = REGISTERS_WR_SOURCE
REGISTERS_WR_SOURCE_SRC = 2 * REGISTERS_WR_SOURCE

RAM_WR = allocate_bit(1)
MEM_VALID = allocate_bit(1)
IMM8 = allocate_bit(1)
IMM16 = allocate_bit(1)

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

def generate_clr(opcode):
    start = opcode * OPCODE_SIZE
    microcode[start] = 0
    microcode[start+1] = NEXT
    microcode[start+2] = 0
    microcode[start+3] = ALU_OP_CLR | REGISTERS_WR | REGISTERS_WR_SOURCE_OP1 | NEXT | STAGE_RESET

def generate_set(opcode):
    start = opcode * OPCODE_SIZE
    microcode[start] = 0
    microcode[start+1] = NEXT
    microcode[start+2] = 0
    microcode[start+3] = ALU_OP_SET | REGISTERS_WR | REGISTERS_WR_SOURCE_OP1 | NEXT | STAGE_RESET

def generate_inc(opcode):
    start = opcode * OPCODE_SIZE
    microcode[start] = 0
    microcode[start+1] = NEXT
    microcode[start+2] = 0
    microcode[start+3] = ALU_OP_INC | REGISTERS_WR | REGISTERS_WR_SOURCE_OP1 | NEXT | STAGE_RESET

def generate_dec(opcode):
    start = opcode * OPCODE_SIZE
    microcode[start] = 0
    microcode[start+1] = NEXT
    microcode[start+2] = 0
    microcode[start+3] = ALU_OP_DEC | REGISTERS_WR | REGISTERS_WR_SOURCE_OP1 | NEXT | STAGE_RESET

def generate_not(opcode):
    start = opcode * OPCODE_SIZE
    microcode[start] = 0
    microcode[start+1] = NEXT
    microcode[start+2] = 0
    microcode[start+3] = ALU_OP_NOT | REGISTERS_WR | REGISTERS_WR_SOURCE_OP1 | NEXT | STAGE_RESET

def generate_neg(opcode):
    start = opcode * OPCODE_SIZE
    microcode[start] = 0
    microcode[start+1] = NEXT
    microcode[start+2] = 0
    microcode[start+3] = ALU_OP_NEG | REGISTERS_WR | REGISTERS_WR_SOURCE_OP1 | NEXT | STAGE_RESET

def generate_movrr(opcode):
    start = opcode * OPCODE_SIZE
    microcode[start] = 0
    microcode[start+1] = NEXT
    microcode[start+2] = 0
    microcode[start+3] = NEXT
    microcode[start+4] = ALU_OP_MOV | REGISTERS_WR | REGISTERS_WR_SOURCE_SRC | NEXT | STAGE_RESET

def generate_movri8(opcode):
    start = opcode * OPCODE_SIZE
    microcode[start] = 0
    microcode[start+1] = NEXT
    microcode[start+2] = NEXT
    microcode[start+3] = ALU_OP_MOV | REGISTERS_WR | REGISTERS_WR_SOURCE_SRC | IMM8 | NEXT | STAGE_RESET

def generate_movri16(opcode):
    start = opcode * OPCODE_SIZE
    microcode[start] = 0
    microcode[start+1] = NEXT
    microcode[start+2] = NEXT
    microcode[start+3] = NEXT
    microcode[start+4] = ALU_OP_MOV | REGISTERS_WR | REGISTERS_WR_SOURCE_SRC | IMM16 | NEXT | STAGE_RESET

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

# two byte instructions
generate_clr(4)
generate_set(5)
generate_inc(6)
generate_dec(7)
generate_not(8)
generate_neg(9)

# alu instructions - 3 byte
generate_movrr(10)
generate_movri8(11)

# alu instructions - 4 byte
generate_movri16(12)

# load/store instructions - 3 byte
generate_lb(50)
generate_lw(51)
generate_sb(52)
generate_sw(53)

# in/out instructions - 3 byte
generate_in(54)
generate_out(55)

# rcall/rjmp instructions - 2 byte
generate_rcall(56)
generate_rjmp(57)

# call/jmp instructions - 3 byte
generate_call(58)
generate_jmp(59)

# branch instructions - 2 byte
generate_br(60)

print_microcode()
