const int microcodeLength = 1024;
const int stageReset = 1;
const int ioRd = 2;
const int ioWr = 4;
const int ioDataDirection = 8;
const int addressLoad = 0x10;
const int addressSourceImmediate = 0x20;
const int addressSourceRegister = 0;
const int ioAddressSourceRegisters2316PlusImmediate3124 = 0x40;
const int ioAddressSourceRegisters3124 = 0;
const int ioDataOutSource = 0x80;
const int aluClk = 0x100;
const int conditionNeg = 0x200;
const int conditonFlagN = 0x400;
const int conditonFlagZ = 0x800;
const int conditonFlagC = 0x1000;
const int aluOp1SourceRegisters158 = 0x200;
const int aluOp1SourceRegisters2316 = 0;
const int aluOp2SourceRegisters3124 = 0;
const int aluOp2SourceInstruction3116 = 0x400;
const int aluOp2SourceIoData = 0x800;
const int hlt = 0x2000;
const int error = 0x4000;
const int push = 0x8000;
const int inInterruptClear = 0x8000;
const int pop = 0x10000;
const int registersWr = 0x20000;
const int registersWrDestInstruction2316 = 0x40000;
const int registersWrDestInstruction158 = 0;
const int registersWrSourceAluOut = 0;
const int registersWrSourceAluOut2 = 0x80000;
const int registersWrSourceImmediate = 0x100000;
const int registersWrSourceRegisterData1 = 0x180000;
const int registersWrSourceRegisterData2PlusImmediate = 0x200000;
const int registersWrSourceRegisterData3 = 0x280000;
const int registersWrSourceFlags = 0x300000;
const int registersWrSourceIoData = 0x380000;

for (var i = 0; i < microcodeLength; i++)
{
    var v = 0;
    var stage = i & 3;
    var opType = i >> 6;
    var opSubtype = (i >> 2) & 0x0F;
    v |= stage switch
    {
        0 => opType switch
        {
            // jmp addr
            0 => addressLoad | addressSourceImmediate | BuildCondition(i) | stageReset | ioRd | ioWr | ioDataDirection,
            // jmp reg
            1 => addressLoad | BuildCondition(i) | stageReset | ioRd | ioWr | ioDataDirection,
            // call addr
            2 => addressLoad | addressSourceImmediate | push | BuildCondition(i) | stageReset |
                 ioRd | ioWr | ioDataDirection,
            // call reg
            3 => addressLoad | push | BuildCondition(i) | stageReset | ioRd | ioWr | ioDataDirection,
            // ret
            4 => addressLoad | pop | BuildCondition(i) | stageReset | ioRd | ioWr | ioDataDirection,
            5 => opSubtype switch
            {
                // reti
                >= 0 and <= 6 => addressLoad | pop | BuildCondition(i) | inInterruptClear | stageReset |
                                 ioRd | ioWr | ioDataDirection,
                // mov flags to register
                0x0B => stageReset | registersWr | registersWrSourceFlags | registersWrDestInstruction158 |
                        ioRd | ioWr | ioDataDirection,
                // nop
                0x0C => stageReset | ioRd | ioWr | ioDataDirection,
                // mov reg immediate
                0x0D => stageReset | registersWr | registersWrSourceImmediate | registersWrDestInstruction158 |
                        ioRd | ioWr | ioDataDirection,
                // mov reg reg
                0x0E => stageReset | registersWr | registersWrSourceRegisterData2PlusImmediate |
                        registersWrDestInstruction158 | ioRd | ioWr | ioDataDirection,
                // hlt
                0x0F => hlt | stageReset,
                _ => hlt | error | ioRd | ioWr | ioDataDirection
            },
            // alu instruction, register->register
            >= 6 and <= 7 => aluClk | aluOp1SourceRegisters2316 | aluOp2SourceRegisters3124 | registersWr |
                                registersWrSourceAluOut | registersWrDestInstruction158 | stageReset |
                                ioRd | ioWr | ioDataDirection,
            // alu instruction, immediate->register
            >= 8 and <= 9 => aluClk | aluOp1SourceRegisters158 | aluOp2SourceInstruction3116 | registersWr |
                             registersWrSourceAluOut | registersWrDestInstruction158 | stageReset |
                             ioRd | ioWr | ioDataDirection,
            // alu instruction, io->register
            >= 10 and <= 11 => aluClk | aluOp1SourceRegisters2316 | aluOp2SourceIoData | registersWr |
                               registersWrSourceAluOut | registersWrDestInstruction158 | ioAddressSourceRegisters3124 |
                               stageReset | ioWr | ioDataDirection,
            // alu instruction, register->io
            >= 12 and <= 13 => aluClk | ioRd | ioWr | ioDataDirection,
            // operations without ALU with io
            14 => opSubtype switch
            {
                // in io->register
                0 => stageReset | ioWr | ioDataDirection,
                // out register->io
                1 => stageReset | ioRd,
                _ => hlt | error | ioRd | ioWr | ioDataDirection
            },
            // operations without ALU with io
            15 => opSubtype switch
            {
                _ => hlt | error | ioRd | ioWr | ioDataDirection
            },
            _ => hlt | error | ioRd | ioWr | ioDataDirection
        },
        _ => hlt | error | ioRd | ioWr | ioDataDirection
    };
    Console.WriteLine("{0:X6}", v);
}

return;

int BuildCondition(int i)
{
    return ((i >> 2) & 0xF) switch
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