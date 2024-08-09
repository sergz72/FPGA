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

internal sealed class InOutInstructionCreator(uint type) : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, List<Token> parameters)
    {
        if (parameters.Count < 5)
            throw new InstructionException("register name and io address expected");
        int start = 0;
        if (!GetRegisterNumberWithIoFlag(parameters, ref start, true, out var regNo, out var offset1, out var io))
            throw new InstructionException("register name expected");
        if ((type == InstructionCodes.In && io) || (type == InstructionCodes.Out && !io))
            throw new InstructionException("incorrect parameter 1");
        if (start == parameters.Count || !parameters[start].IsChar(','))
            throw new InstructionException(", expected");
        start++;
        if (!GetRegisterNumberWithIoFlag(parameters, ref start, true, out var regNo2, out var offset2, out var io2))
            throw new InstructionException("register2 name expected");
        if ((type == InstructionCodes.In && !io2) || (type == InstructionCodes.Out && io2))
            throw new InstructionException("incorrect parameter 2");

        return new InOutInstruction(line, type, regNo, regNo2, (uint)offset1 | (uint)offset2);
    }
}
