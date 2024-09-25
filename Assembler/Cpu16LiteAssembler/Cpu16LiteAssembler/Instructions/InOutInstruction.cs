using GenericAssembler;

namespace Cpu16LiteAssembler.Instructions;

internal sealed class InOutInstruction : Instruction
{
    private readonly uint _type, _regNo, _regNo2, _adder;
    
    internal InOutInstruction(string line, uint type, uint regNo, uint regNo2, uint adder): base(line)
    {
        _type = type;
        _regNo = regNo;
        _regNo2 = regNo2;
        _adder = adder;
    }
    
    public override uint[] BuildCode(uint labelAddress)
    {
        return [_type | (_regNo << 8) | (_regNo2 << 16) | (_adder << 24)];
    }
}

internal sealed class InInstructionCreator : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, List<Token> parameters)
    {
        if (parameters.Count < 5 || parameters[0].Type != TokenType.Name || !parameters[1].IsChar(',') ||
            !GetRegisterNumber(compiler, parameters[0].StringValue, out var regNo))
            throw new InstructionException("register name and io address expected");
        var start = 2;
        if (!OutInstructionCreator.GetRegisterNumberWithIoFlag(compiler, parameters, ref start, true,
                                                                out var regNo2, out var offset, out var io))
            throw new InstructionException("io address expected");
        if (!io)
            throw new InstructionException("incorrect io address format");

        return new InOutInstruction(line, InstructionCodes.In, regNo, regNo2, (uint)offset);
    }
}

internal sealed class OutInstructionCreator : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, List<Token> parameters)
    {
        if (parameters.Count < 5)
            throw new InstructionException("io address and register name expected");
        var start = 0;
        if (!GetRegisterNumberWithIoFlag(compiler, parameters, ref start, true, out var regNo, out var offset, out var io))
            throw new InstructionException("io address expected");
        if (!io)
            throw new InstructionException("incorrect io address");
        if (start == parameters.Count || !parameters[start].IsChar(','))
            throw new InstructionException(", expected");
        start++;
        if (start == parameters.Count)
            throw new InstructionException("unexpected end of line");
        if (MovInstructionCreator.ParseRp(parameters, ref start, out var increment, out var decrement))
            return CreateIndirect(line, regNo, offset, increment, decrement);
        if (parameters[start].Type != TokenType.Name ||
            !GetRegisterNumber(compiler, parameters[start].StringValue, out var regNo2))
            throw new InstructionException("register name expected");

        return new InOutInstruction(line, InstructionCodes.Out, regNo2, regNo, (uint)offset);
    }

    private Instruction CreateIndirect(string line, uint regNo, int offset, bool increment, bool decrement)
    {
        if (increment)
            return new InOutInstruction(line, InstructionCodes.OutRpInc, 0, regNo, (uint)offset);
        if (decrement)
            return new InOutInstruction(line, InstructionCodes.OutRpDec, 0, regNo, (uint)offset);
        return new InOutInstruction(line, InstructionCodes.OutRp, 0, regNo, (uint)offset);
    }
    
    internal static bool GetRegisterNumberWithIoFlag(ICompiler compiler, List<Token> parameters, ref int start, bool withOffset,
        out uint regNo, out int offset, out bool io)
    {
        if (start == parameters.Count)
            throw new InstructionException("unexpected end of line");

        io = false;
        if (parameters[start].IsChar('['))
        {
            io = true;
            start++;
        }

        if (start == parameters.Count)
            throw new InstructionException("unexpected end of line");

        if (parameters[start].Type != TokenType.Name ||
            !GetRegisterNumber(compiler, parameters[start].StringValue, out regNo))
        {
            if (io) throw new InstructionException("register name expected");
            regNo = 0;
            offset = 0;
            return false;
        }

        start++;

        if (!io)
        {
            offset = 0;
            return true;
        }

        if (withOffset)
        {
            if (start == parameters.Count)
                throw new InstructionException("unexpected end of line");

            if (parameters[start].IsChar('+'))
            {
                start++;
                ReadOffset(compiler, parameters, ref start, out offset);
            }
            else if (parameters[start].IsChar('-'))
            {
                start++;
                ReadOffset(compiler, parameters, ref start, out var off);
                offset = -off;
            }
            else
                offset = 0;
        }
        else
            offset = 0;

        if (start == parameters.Count || !parameters[start].IsChar(']'))
            throw new InstructionException("] expected");
        start++;
        
        return true;
    }
}
