const int microcodeLength = 256;
const int ioRd = 1;
const int ioWr = 2;
const int addressLoad = 4;
const int addressSourceImmediate = 8;
const int addressSourceRegister = 0;
const int aluClk = 0x10;
const int conditionNeg = 0x20;
const int conditonFlagN = 0x40;
const int conditonFlagZ = 0x80;
const int conditonFlagC = 0x100;
const int aluOp1SourceRegisters158 = 0x200;
const int aluOp1SourceRegisters2316 = 0;
const int aluOp2SourceRegisters3124 = 0;
const int aluOp2SourceInstruction3116 = 0x400;
const int hlt = 0x800;
const int error = 0x1000;
const int push = 0x2000;
const int inInterruptClear = 0x4000;
const int pop = 0x8000;
const int registersWr = 0x10000;
const int registersWrDestInstruction2316 = 0x20000;
const int registersWrDestInstruction158 = 0;
const int registersWrSourceAluOut = 0;
const int registersWrSourceAluOut2 = 0x40000;
const int registersWrSourceImmediate = 0x80000;
const int registersWrSourceRegisterData1 = 0xC0000;
const int registersWrSourceRegisterData2PlusImmediate = 0x100000;
const int registersWrSourceRegisterData3 = 0x140000;
const int registersWrSourceFlags = 0x180000;
const int registersWrSourceIoData = 0x1C0000;

for (var i = 0; i < microcodeLength; i++)
{
    var opType = i >> 4;
    var opSubtype = i & 0x0F;
    var v = opType switch
    {
        // jmp addr
        0 => addressLoad | addressSourceImmediate | BuildCondition(opSubtype) | ioRd | ioWr,
        // jmp reg
        1 => addressLoad | BuildCondition(opSubtype) | ioRd | ioWr,
        // call addr
        2 => addressLoad | addressSourceImmediate | push | BuildCondition(opSubtype) | ioRd | ioWr,
        // call reg
        3 => addressLoad | push | BuildCondition(opSubtype) | ioRd | ioWr,
        // ret
        4 => addressLoad | pop | BuildCondition(opSubtype) | ioRd | ioWr,
        5 => opSubtype switch
        {
            // reti
            >= 0 and <= 6 => addressLoad | pop | BuildCondition(opSubtype) | inInterruptClear | ioRd | ioWr,
            // mov reg alu_out_2
            0x0A => registersWr | registersWrSourceAluOut2 | registersWrDestInstruction158 | ioRd | ioWr,
            // mov flags to register
            0x0B => registersWr | registersWrSourceFlags | registersWrDestInstruction158 | ioRd | ioWr,
            // nop
            0x0C => ioRd | ioWr,
            // mov reg immediate
            0x0D => registersWr | registersWrSourceImmediate | registersWrDestInstruction158 | ioRd | ioWr,
            // mov reg reg
            0x0E => registersWr | registersWrSourceRegisterData2PlusImmediate |
                    registersWrDestInstruction158 | ioRd | ioWr,
            // hlt
            0x0F => hlt | ioRd | ioWr,
            _ => hlt | error | ioRd | ioWr
        },
        // alu instruction, register->register
        >= 6 and <= 7 => aluClk | aluOp1SourceRegisters2316 | aluOp2SourceRegisters3124 | BuildWr(i & 0x1F) | ioRd | ioWr,
        // alu instruction, immediate->register
        >= 8 and <= 9 => aluClk | aluOp1SourceRegisters158 | aluOp2SourceInstruction3116 | BuildWr(i & 0x1F) | ioRd | ioWr,
        // operations without ALU with io
        15 => opSubtype switch
        {
            // in io->register
            0 => ioWr | registersWrSourceIoData | registersWr | registersWrDestInstruction158,
            // out register->io
            1 => ioRd,
            _ => hlt | error | ioRd | ioWr
        },
        _ => hlt | error | ioRd | ioWr
    };
    Console.WriteLine("{0:X6}", v);
}

return;

int BuildWr(int aluOp)
{
    if (aluOp is 0 or 11) // test or cmp
        return 0;
    return registersWr | registersWrSourceAluOut | registersWrDestInstruction158;
}

int BuildCondition(int opSubType)
{
    return opSubType switch
    {
        // no condition
        0 => conditionNeg,
        // c == 1
        1 => conditonFlagC,
        // c == 0
        2 => conditonFlagC | conditionNeg,
        // z == 1
        3 => conditonFlagZ,
        // z == 0
        4 => conditonFlagZ | conditionNeg,
        // z == 0 && c == 0
        5 => conditonFlagC | conditonFlagZ | conditionNeg,
        // z == 1 || c == 1
        6 => conditonFlagC | conditonFlagZ,
        _ => hlt | error
    };
}