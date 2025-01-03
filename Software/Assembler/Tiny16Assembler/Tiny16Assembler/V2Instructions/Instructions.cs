﻿using GenericAssembler;

namespace Tiny16Assembler.V2Instructions;

internal static class AluOperations
{
    internal const uint Test = 0;
    internal const uint Cmp = 1;
    internal const uint Setf = 2;

    internal const uint Neg = 4;
    internal const uint Add = 5;
    internal const uint Adc = 6;
    internal const uint Sub = 7;
    internal const uint Sbc = 8;
    internal const uint Shl = 9;
    internal const uint Shr = 10;
    internal const uint And = 11;
    internal const uint Or  = 12;
    internal const uint Xor = 13;
    internal const uint Rlc   = 14;
    internal const uint Rrc   = 15;
    internal const uint Shlc  = 16;
    internal const uint Shrc  = 17;

    internal const uint Div1616 = 27;
    internal const uint Rem1616 = 28;
    internal const uint Div3216 = 29;
    internal const uint Rem3216 = 30;
    internal const uint Mul = 31;
}

internal static class Conditions
{
    internal const uint None = 8;
    internal const uint C = 4;
    internal const uint Z = 2;
    internal const uint MI = 1; // N
    internal const uint NC = 4 + 8;
    internal const uint NZ = 2 + 8;
    internal const uint PL = 1 + 8; // not N
    internal const uint GT = 4 + 2 + 8; // not C & not Z
    internal const uint LE = 4 + 2; // C | Z
}

internal static class InstructionCodes
{
    internal const uint Hlt = 0;
    internal const uint Nop = 1;
    internal const uint MovRImm = 2;
    internal const uint Jmp = 3;
    internal const uint Mvil = 4;
    internal const uint Mvih = 8;
    internal const uint Br = 12;
    internal const uint Call = 16;
    internal const uint Ret = 17;
    internal const uint Reti = 18;
    internal const uint Int = 19;
    internal const uint MovMImm = 20;
    internal const uint Jmp11 = 24;
    internal const uint Call11 = 26;
    internal const uint AluRM = 28;
    internal const uint JmpReg = 31;
    internal const uint JmpPReg = 32;
    internal const uint CallReg = 35;
    internal const uint CallPReg = 36;
    internal const uint Pushf = 39;
    internal const uint MovRM = 40;
    internal const uint MovRR = 43;
    internal const uint MovMR = 44;
    internal const uint AluRR = 48;
    internal const uint AluMR = 56;
    internal const uint AluRImm = 59;
    internal const uint AluMImm = 60;
}

internal sealed class OpCodeInstruction(string line, string file, int lineNo, uint opCode, uint parameter) :
    Instruction(line, file, lineNo)
{
    public override uint[] BuildCode(uint labelAddress, uint pc)
    {
        return [(opCode << 10) | parameter];
    }
}

internal sealed class OpCodeInstructionCreator(uint opCode, uint parameter = 0) : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        if (parameters.Count != 0)
            throw new InstructionException("unexpected instruction parameters");
        return new OpCodeInstruction(line, file, lineNo, opCode, parameter);
    }
}

record MemoryOp(bool PostInc, bool PreDec, int Offset);

internal static class InstructionsHelper
{
    internal static bool GetRegisterNumberWithMemoryFlag(ICompiler compiler, List<Token> parameters, ref int start,
                                                            out uint regNo, out MemoryOp? memoryOp)
    {
        if (start == parameters.Count)
            throw new InstructionException("unexpected end of line");

        memoryOp = null;
        if (parameters[start].IsChar('-'))
        {
            memoryOp = new MemoryOp(false, true, 0);
            start++;
            if (start == parameters.Count)
                throw new InstructionException("unexpected end of line");
        }

        if (parameters[start].Type == TokenType.Number)
        {
            if (memoryOp == null)
                memoryOp = new MemoryOp(false, false, (int)parameters[start].LongValue);
            else
                memoryOp = memoryOp with { Offset = (int)parameters[start].LongValue};
            start++;
            if (start == parameters.Count)
                throw new InstructionException("unexpected end of line");
        }
        if (parameters[start].IsChar('('))
        {
            if (memoryOp == null)
                memoryOp = new MemoryOp(false, false, 0);
            start++;
        }
        else if (memoryOp != null)
            throw new InstructionException("( expected");

        if (start == parameters.Count)
            throw new InstructionException("unexpected end of line");

        if (parameters[start].Type != TokenType.Name ||
            !InstructionCreator.GetRegisterNumber(compiler, parameters[start].StringValue, out regNo))
        {
            if (memoryOp != null) throw new InstructionException("register name expected");
            regNo = 0;
            return false;
        }

        start++;

        if (memoryOp == null)
            return true;
        
        if (start == parameters.Count || !parameters[start].IsChar(')'))
            throw new InstructionException(") expected");
        start++;

        if (start <= parameters.Count && parameters[start].IsChar('+'))
        {
            if (memoryOp.PreDec)
                throw new InstructionException("both post increment and pre decrement are present");
            memoryOp = memoryOp with {PostInc = true};
            start++;
        }
        
        return true;
    }
}