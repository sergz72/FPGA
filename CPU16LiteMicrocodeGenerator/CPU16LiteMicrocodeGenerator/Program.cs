const int microcodeLength = 256;
const int ioRd = 1;
const int ioWr = 2;
const int addressLoad = 4;
const int addressSourceImmediate = 8;
const int addressSourceRegistersData1PlusImmediate = 0;
const int aluClk = 0x10;
const int conditionNeg = 0x20;
const int conditonFlagN = 0x40;
const int conditonFlagZ = 0x80;
const int conditonFlagC = 0x100;
const int aluOp2SourceRegistersData2 = 0;
const int aluOp2SourceImmediate = 0x200;
const int hlt = 0x400;
const int error = 0x800;
const int push = 0x1000;
const int inInterruptClear = 0x2000;
const int pop = 0x4000;
const int registersWr = 0x8000;
const int registersWrDestInstruction158 = 0;
const int registersWrDestSp = 0x10000;
const int registersWrDestRpMinus1 = 0x20000;
const int registersWrDestRp = 0x30000;
const int registersWrSourceAluOut = 0;
const int registersWrSourceImmediate = 0x40000;
const int registersWrSourceRegisterData1PlusImmediate8 = 0x80000;
const int registersWrSourceRegisterData1PlusImmediate16 = 0xC0000;
const int registersWrSourceFlags = 0x100000;
const int registersWrSourcePrevAddress = 0x140000;
const int registersWrSourceIoData = 0x180000;
const int rpOpNone = 0;
const int rpOpLoad = 0x200000;
const int rpOpIncrement = 0x400000;
const int rpOpDecrement = 0x600000;
const int registersRdSource1Instruction2316 = 0;
const int registersRdSource1Instruction158 = 0x800000;
const int registersRdSource1Sp = 0x1000000;
const int registersRdSource1Rp = 0x1800000;
const int registersRdSource2Instruction3124 = 0;
const int registersRdSource2Instruction2316 = 0x2000000;
const int registersRdSource2Sp = 0x4000000;
const int registersRdSource2Rp = 0x6000000;

for (var i = 0; i < microcodeLength; i++)
{
    var opType = i >> 4;
    var opSubtype = i & 0x0F;
    var v = opType switch
    {
        // jmp addr
        0 => addressLoad | addressSourceImmediate | BuildCondition(opSubtype) | ioRd | ioWr,
        // jmp reg
        1 => addressLoad | addressSourceRegistersData1PlusImmediate | registersRdSource1Instruction158 |
             BuildCondition(opSubtype) | ioRd | ioWr,
        // call addr
        2 => addressLoad | addressSourceImmediate | push | BuildCondition(opSubtype) | ioRd | ioWr | registersWr |
             registersWrSourcePrevAddress | registersWrDestSp,
        // call reg
        3 => addressLoad | push | addressSourceRegistersData1PlusImmediate | registersRdSource1Instruction158 |
             BuildCondition(opSubtype) | ioRd | ioWr | registersWr | registersWrSourcePrevAddress | registersWrDestSp,
        // ret
        4 => addressLoad | pop | BuildCondition(opSubtype) | ioRd | ioWr | registersRdSource1Sp,
        5 => opSubtype switch
        {
            // reti
            >= 0 and <= 6 => addressLoad | pop | BuildCondition(opSubtype) | inInterruptClear | ioRd | ioWr |
                             registersRdSource1Sp,
            // inc rp
            0x08 => ioRd | ioWr | rpOpIncrement,
            // dec rp
            0x09 => ioRd | ioWr | rpOpDecrement,
            //load rp
            0x0A => ioRd | ioWr | rpOpLoad,
            // mov flags to register
            0x0B => registersWr | registersWrSourceFlags | registersWrDestInstruction158 | ioRd | ioWr,
            // nop
            0x0C => ioRd | ioWr,
            // mov reg immediate
            0x0D => registersWr | registersWrSourceImmediate | registersWrDestInstruction158 | ioRd | ioWr,
            // mov reg reg
            0x0E => registersWr | registersWrSourceRegisterData1PlusImmediate8 | registersRdSource1Instruction2316 |
                    registersWrDestInstruction158 | ioRd | ioWr,
            // hlt
            0x0F => hlt | ioRd | ioWr,
            _ => hlt | error | ioRd | ioWr
        },
        // alu instruction, register->register
        >= 6 and <= 7 => aluClk | aluOp2SourceRegistersData2 | BuildWr(i & 0x1F) |
                         ioRd | ioWr | registersRdSource1Instruction2316 | registersRdSource2Instruction3124,
        // alu instruction, immediate->register
        >= 8 and <= 9 => aluClk | aluOp2SourceImmediate | BuildWr(i & 0x1F) |
                         ioRd | ioWr | registersRdSource1Instruction158,
        // mov with rp
        14 => opSubtype switch
        {
            // mov @rp immediate
            0 => registersWr | registersWrSourceImmediate | registersWrDestRp | ioRd | ioWr,
            1 => registersWr | registersWrSourceImmediate | registersWrDestRpMinus1 | ioRd | ioWr | rpOpIncrement,
            2 => registersWr | registersWrSourceImmediate | registersWrDestRp | ioRd | ioWr | rpOpDecrement,
            // mov @rp reg
            4 => registersWr | registersWrSourceRegisterData1PlusImmediate16 | registersRdSource1Instruction158 |
                  registersWrDestRp | ioRd | ioWr,
            5 => registersWr | registersWrSourceRegisterData1PlusImmediate16 | registersRdSource1Instruction158 |
                  registersWrDestRpMinus1 | ioRd | ioWr | rpOpIncrement,
            6 => registersWr | registersWrSourceRegisterData1PlusImmediate16 | registersRdSource1Instruction158 |
                  registersWrDestRp | ioRd | ioWr | rpOpDecrement,
            // mov reg, @rp
            8 => registersWr | registersWrSourceRegisterData1PlusImmediate16 | registersRdSource1Rp |
                 registersWrDestInstruction158 | ioRd | ioWr,
            9 => registersWr | registersWrSourceRegisterData1PlusImmediate16 | registersRdSource1Rp |
                 registersWrDestInstruction158 | ioRd | ioWr | rpOpIncrement,
            10 => registersWr | registersWrSourceRegisterData1PlusImmediate8 | registersRdSource1Rp |
                 registersWrDestInstruction158 | ioRd | ioWr | rpOpDecrement,
            _ => hlt | error | ioRd | ioWr
        },
        // operations without ALU with io
        15 => opSubtype switch
        {
            // in io->register
            0 => ioWr | registersWrSourceIoData | registersWr | registersWrDestInstruction158 | registersRdSource2Instruction2316,
            1 => ioWr | registersWrSourceIoData | registersWr | registersWrDestRp | registersRdSource2Instruction2316,
            2 => ioWr | registersWrSourceIoData | registersWr | registersWrDestRp | rpOpDecrement | registersRdSource2Instruction2316,
            3 => ioWr | registersWrSourceIoData | registersWr | registersWrDestRpMinus1 | rpOpDecrement | registersRdSource2Instruction2316,
            // out register->io
            4 => ioRd | registersRdSource2Instruction2316 | registersRdSource1Instruction158,
            5 => ioRd | registersRdSource2Instruction2316 | registersRdSource1Rp,
            6 => ioRd | rpOpIncrement | registersRdSource2Instruction2316 | registersRdSource1Rp,
            7 => ioRd | rpOpDecrement | registersRdSource2Instruction2316 | registersRdSource1Rp,
            _ => hlt | error | ioRd | ioWr
        },
        _ => hlt | error | ioRd | ioWr
    };
    Console.WriteLine("{0:X7}", v);
}

return;

int BuildWr(int aluOp)
{
    if (aluOp is 0 or 11 or 12) // test or cmp or setf
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