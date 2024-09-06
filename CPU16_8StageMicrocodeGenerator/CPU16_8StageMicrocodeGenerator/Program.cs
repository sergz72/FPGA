const int microcodeLength = 512;
//microcode word 1
const int ioRd = 1;
const int ioWr = 2;

const int addressLoad = 4;
const int addressSourceImmediate = 0;
const int addressSourceRamData1PlusImmediate = 8;
const int addressSourceRamData3PlusImmediate = 0x10;
const int addressSourceIOData = 0x18;

const int aluClk = 0x20;

const int conditionNeg = 0x40;
const int conditonFlagN = 0x80;
const int conditonFlagZ = 0x100;
const int conditonFlagC = 0x200;

const int hlt = 0x400;
const int error = 0x800;
const int push = 0x1000;
const int inInterruptClear = 0x2000;
const int pop = 0x4000;

const int ramWr1 = 0x8000;
const int ramWr2 = 0x10000;
const int ramWr1DestInstruction158 = 0;
const int ramWr1DestSp = 0x20000;
const int ramWr1SourceAluOut = 0;
const int ramWr1SourceImmediate = 0x80000;
const int ramWr1SourceRegisterData1PlusImmediate8 = 0x100000;
const int ramWr1SourceRegisterData1PlusImmediate16 = 0x180000;
const int ramWr1SourceFlags = 0x200000;
const int ramWr1SourcePrevAddress = 0x280000;
const int ramWr1SourceIoData = 0x300000;

const int ramWr2DestInstruction158 = 0;
const int ramWr2DestSp = 0x400000;
const int ramWr2SourceAluOut = 0;
const int ramWr2SourceImmediate = 0x800000;
const int ramWr2SourceRegisterData1PlusImmediate8 = 0x1000000;
const int ramWr2SourceRegisterData1PlusImmediate16 = 0x1800000;
const int ramWr2SourceFlags = 0x2000000;
const int ramWr2SourcePrevAddress = 0x2800000;
const int ramWr2SourceIoData = 0x3000000;

//microcode word 2
const int ramRdSource1Instruction2316 = 0;
const int ramRdSource1Instruction158 = 1;
const int ramRdSource1Sp = 2;

const int ramRdSource2Instruction3124 = 0;
const int ramRdSource2Instruction2316 = 4;
const int ramRdSource2Sp = 8;

const int ramRdSource3RamData1 = 0;
const int ramRdSource3Instruction2316 = 0x10;
const int ramRdSource3Sp = 0x20;

const int ramRdSource4Instruction3124 = 0;
const int ramRdSource4Instruction2316 = 0x40;
const int ramRdSource4Sp = 0x80;

const int ioDataOutSource1 = 0;
const int ioDataOutSource2 = 0x100;

const int ioAddressSource1 = 0;
const int ioAddressSource2 = 0x200;
const int ioAddressSource3 = 0x400;
const int ioAddressSource4 = 0x600;

const int aluOp1SourceRamData1 = 0;
const int aluOp1SourceRamData3 = 0x800;

const int aluOp2SourceRamData2 = 0;
const int aluOp2SourceImmediate = 0x1000;
const int aluOp2Source3 = 0x2000;

for (var i = 0; i < microcodeLength / 2; i += 2)
{
    var opType = i >> 4;
    var opSubtype = i & 0x0F;
    var v1 = opType switch
    {
        // jmp addr
        0 => addressLoad | addressSourceImmediate | BuildCondition(opSubtype) | ioRd | ioWr,
        // jmp reg
        1 => addressLoad | addressSourceRamData1PlusImmediate | ramRdSource1Instruction158 |
             BuildCondition(opSubtype) | ioRd | ioWr,
        // jmp @reg
        2 => addressLoad | addressSourceRamData3PlusImmediate | ramRdSource3RamData1 | ramRdSource1Instruction158 |
             BuildCondition(opSubtype) | ioRd | ioWr,
        // call addr
        3 => addressLoad | addressSourceImmediate | push | BuildCondition(opSubtype) | ioRd | ioWr,
        // call reg
        4 => addressLoad | push | addressSourceRamData1PlusImmediate | ramRdSource1Instruction158 |
             BuildCondition(opSubtype) | ioRd | ioWr,
        // call @reg
        5 => addressLoad | push | addressSourceRamData3PlusImmediate | ramRdSource3RamData1 | ramRdSource1Instruction158 |
             BuildCondition(opSubtype) | ioRd | ioWr,
        // ret
        6 => addressLoad | pop | BuildCondition(opSubtype) | ioRd | ioWr | ramRdSource1Sp,
        7 => opSubtype switch
        {
            // reti
            >= 0 and <= 6 => addressLoad | pop | BuildCondition(opSubtype) | inInterruptClear | ioRd | ioWr |
                             ramRdSource1Sp,
            // pop reg
            0x0B => ramWr1 | ramWr1SourceRamData3 | ramRdSource1Sp | ioRd | ioWr,
            // push reg
            0x0C => ioRd | ioWr,
            // mov flags to register
            0x0D => ramWr1 | ramWr1SourceFlags | ramWr1DestInstruction158 | ioRd | ioWr,
            // nop
            0x0E => ioRd | ioWr,
            // hlt
            0x0F => hlt | ioRd | ioWr,
            _ => hlt | error | ioRd | ioWr
        },
        // alu instruction, register,register->register
        >= 8 and <= 9 => aluClk | aluOp2SourceRamData2 | aluOp1SourceRamData1 | BuildWr(i & 0x1F) |
                         ioRd | ioWr | ramRdSource1Instruction2316 | ramRdSource2Instruction3124,
        // alu instruction, @register,register->register
        >= 10 and <= 11 => aluClk | aluOp1SourceRamData1 | aluOp2SourceRamData3 | BuildWr(i & 0x1F) |
                         ioRd | ioWr | ramRdSource1Instruction2316 | ramRdSource2Instruction3124,
        // alu instruction, immediate->register
        >= 12 and <= 13 => aluClk | aluOp2SourceImmediate | BuildWr(i & 0x1F) |
                         ioRd | ioWr | ramRdSource1Instruction158,
        // mov
        14 => opSubtype switch
        {
            // mov reg reg
            0x00 => ramWr1 | ramWr1SourceRegisterData1PlusImmediate8 | ramRdSource1Instruction2316 |
                    ramWr1DestInstruction158 | ioRd | ioWr,
            // mov @reg reg
            0x01 => ramWr1 | ramWr1SourceRegisterData3PlusImmediate8 | RamRdSource3RamData1 | ramRdSource1Instruction2316 |
                    ramWr1DestInstruction158 | ioRd | ioWr,
            // mov @reg++ reg
            0x02 => ramWr1 | ramWr1SourceRegisterData3PlusImmediate8 | RamRdSource3RamData1 | ramRdSource1Instruction2316 |
                    ramWr1DestInstruction158 | ioRd | ioWr,
            // mov @--reg reg
            0x03 => ramWr1 | ramWr1SourceRegisterData3PlusImmediate8 | RamRdSource3RamData1 | ramRdSource1Instruction2316 |
                    ramWr1DestInstruction158 | ioRd | ioWr,
            // mov reg @reg
            0x04 => ramWr1 | ramWr1SourceRegisterData3PlusImmediate8 | RamRdSource3RamData1 | ramRdSource1Instruction2316 |
                    ramWr1DestInstruction158 | ioRd | ioWr,
            // mov reg @reg++
            0x05 => ramWr1 | ramWr1SourceRegisterData3PlusImmediate8 | RamRdSource3RamData1 | ramRdSource1Instruction2316 |
                    ramWr1DestInstruction158 | ioRd | ioWr,
            // mov reg @--reg
            0x06 => ramWr1 | ramWr1SourceRegisterData3PlusImmediate8 | RamRdSource3RamData1 | ramRdSource1Instruction2316 |
                    ramWr1DestInstruction158 | ioRd | ioWr,
            // mov reg immediate
            0x07 => ramWr1 | ramWr1SourceImmediate | ramWr1DestInstruction158 | ioRd | ioWr,
            // mov @reg immediate
            0x08 => ramWr1 | ramWr1SourceImmediate | ramWr1DestInstruction158 | ioRd | ioWr,
            // mov @reg++ immediate
            0x09 => ramWr1 | ramWr1SourceImmediate | ramWr1DestInstruction158 | ioRd | ioWr,
            // mov @--reg immediate
            0x0A => ramWr1 | ramWr1SourceImmediate | ramWr1DestInstruction158 | ioRd | ioWr,
            // mov sp reg
            0x0B => 0,
            // mov reg, sp
            0x0C => 0,
            // mov reg @sp + n
            0x0D => 0,
            _ => hlt | error | ioRd | ioWr
        }
        // io operations
        15 => opSubtype switch
        {
            // in io->register
            0 => ioWr | ramWrSourceIoData | ramWr | ramWrDestInstruction158 | ramRdSource2Instruction2316,
            // in io->@register
            1 => ioWr | ramWrSourceIoData | ramWr | ramWrDestRp | ramRdSource2Instruction2316,
            // in io->@register++
            2 => ioWr | ramWrSourceIoData | ramWr | ramWrDestRp | rpOpDecrement | ramRdSource2Instruction2316,
            // in io->@--register
            3 => ioWr | ramWrSourceIoData | ramWr | ramWrDestRpMinus1 | rpOpDecrement | ramRdSource2Instruction2316,
            // out register->io
            4 => ioRd | ramRdSource2Instruction2316 | ramRdSource1Instruction158,
            // out @register->io
            5 => ioRd | ramRdSource2Instruction2316 | ramRdSource1Rp,
            // out @register++->io
            6 => ioRd | rpOpIncrement | ramRdSource2Instruction2316 | ramRdSource1Rp,
            // out @--register->io
            7 => ioRd | rpOpDecrement | ramRdSource2Instruction2316 | ramRdSource1Rp,
            _ => hlt | error | ioRd | ioWr
        },
        _ => hlt | error | ioRd | ioWr
    };
    var v2 = opType switch
    {
        // call addr, call reg, call @reg
        >= 3 and <= 5 => ramWr1 | ramWr1SourcePrevAddress | ramWr1DestSp,
        _ => 0
    };
    Console.WriteLine("{0:X7}", v1);
    Console.WriteLine("{0:X7}", v2);
}

return;

int BuildWr(int aluOp)
{
    if (aluOp is 0 or 11 or 12) // test or cmp or setf
        return 0;
    return ramWr1 | ramWr1SourceAluOut | ramWr1DestInstruction158;
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
        // n == 1
        7 => conditonFlagN,
        // n == 0
        8 => conditonFlagN | conditionNeg,
        _ => hlt | error
    };
}
