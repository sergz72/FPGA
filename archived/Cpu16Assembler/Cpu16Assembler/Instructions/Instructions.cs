﻿using GenericAssembler;

namespace Cpu16Assembler.Instructions;

internal static class AluOperations
{
    internal const uint Test = 0;
    internal const uint Neg = 1;
    internal const uint Add = 2;
    internal const uint Adc = 3;
    internal const uint Sub = 4;
    internal const uint Sbc = 5;
    internal const uint Shl = 6;
    internal const uint Shr = 7;
    internal const uint And = 8;
    internal const uint Or  = 9;
    internal const uint Xor = 10;
    internal const uint Cmp = 11;
    internal const uint Mul = 12;
    internal const uint Div = 13;
    internal const uint Rem = 14;
    internal const uint Setf = 15;
    internal const uint Setf2 = 16;
    internal const uint Rlc   = 17;
    internal const uint Rrc   = 18;
    internal const uint Shlc  = 19;
    internal const uint Shrc  = 20;
}

internal static class InstructionCodes
{
    internal const uint JmpAddr = 0;
    internal const uint JmpcAddr = 1;
    internal const uint JmpncAddr = 2;
    internal const uint JmpzAddr = 3;
    internal const uint JmpnzAddr = 4;
    internal const uint JmpGtAddr = 5;
    internal const uint JmpLeAddr = 6;
    internal const uint JmpReg = 0x10;
    internal const uint JmpcReg = 0x11;
    internal const uint JmpncReg = 0x12;
    internal const uint JmpzReg = 0x13;
    internal const uint JmpnzReg = 0x14;
    internal const uint JmpGtReg = 0x15;
    internal const uint JmpLeReg = 0x16;

    internal const uint CallAddr = 0x20;
    internal const uint CallcAddr = 0x21;
    internal const uint CallncAddr = 0x22;
    internal const uint CallzAddr = 0x23;
    internal const uint CallnzAddr = 0x24;
    internal const uint CallGtAddr = 0x25;
    internal const uint CallLeAddr = 0x26;
    internal const uint CallReg = 0x30;
    internal const uint CallcReg = 0x31;
    internal const uint CallncReg = 0x32;
    internal const uint CallzReg = 0x33;
    internal const uint CallnzReg = 0x34;
    internal const uint CallGtReg = 0x35;
    internal const uint CallLeReg = 0x36;

    internal const uint Ret = 0x40;
    internal const uint Retc = 0x41;
    internal const uint Retnc = 0x42;
    internal const uint Retz = 0x43;
    internal const uint Retnz = 0x44;
    internal const uint RetGt = 0x45;
    internal const uint RetLe = 0x46;

    internal const uint Reti = 0x50;
    internal const uint Retic = 0x51;
    internal const uint Retinc = 0x52;
    internal const uint Retiz = 0x53;
    internal const uint Retinz = 0x54;
    internal const uint RetiGt = 0x55;
    internal const uint RetiLe = 0x56;
    
    internal const uint MovAluOut2 = 0x5A;
    internal const uint Loadf = 0x5B;
    internal const uint Nop = 0x5C;
    internal const uint MovImmediate = 0x5D;
    internal const uint MovReg = 0x5E;
    internal const uint Hlt = 0x5F;

    internal const uint In = 0xF0;
    internal const uint Out = 0xF1;
}

internal sealed class OpCodeInstruction(string line, uint opCode) : Instruction(line)
{
    public override uint BuildCode(ushort labelAddress)
    {
        return opCode;
    }
}

internal sealed class OpCodeInstructionCreator(uint opCode) : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, List<Token> parameters)
    {
        if (parameters.Count != 0)
            throw new InstructionException("unexpected instruction parameters");
        return new OpCodeInstruction(line, opCode);
    }
}