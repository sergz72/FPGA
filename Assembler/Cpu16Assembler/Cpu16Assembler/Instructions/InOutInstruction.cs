using GenericAssembler;

namespace Cpu16Assembler.Instructions;

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
    
    public override uint BuildCode(ushort labelAddress)
    {
        return _type | (_regNo << 8) | (_regNo2 << 16) | (_adder << 24);
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
        if (!GetRegisterNumberWithIoFlag(compiler, parameters, ref start, true, out var regNo2, out var offset, out var io))
            throw new InstructionException("io address expected");
        if (!io)
            throw new InstructionException("incorrect io address format");

        return new InOutInstruction(line, InstructionCodes.In, regNo, regNo2, (uint)offset);
    }
}

internal sealed class OutInstructionCreator() : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, List<Token> parameters)
    {
        if (parameters.Count < 5)
            throw new InstructionException("io address and register name expected");
        int start = 0;
        if (!GetRegisterNumberWithIoFlag(compiler, parameters, ref start, true, out var regNo, out var offset, out var io))
            throw new InstructionException("io address expected");
        if (!io)
            throw new InstructionException("incorrect io address");
        if (start == parameters.Count || !parameters[start].IsChar(','))
            throw new InstructionException(", expected");
        start++;
        if (start == parameters.Count || parameters[start].Type != TokenType.Name ||
            !GetRegisterNumber(compiler, parameters[start].StringValue, out var regNo2))
            throw new InstructionException("register name expected");

        return new InOutInstruction(line, InstructionCodes.Out, regNo2, regNo, (uint)offset);
    }
}
