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
        if (parameters.Count < 3 || parameters[0].Type != TokenType.Name)
            throw new InstructionException("register name and register [+ immediate] expected");
        if (!GetRegisterNumber(parameters[0].StringValue, out var regNo))
            throw new InstructionException("register name expected");
        if (!parameters[1].IsChar(','))
            throw new InstructionException(", expected");
        if (!GetRegisterNumber(parameters[2].StringValue, out var regNo2))
            throw new InstructionException("register name expected");
        var adder = 0;
        if (parameters.Count > 3)
        {
            if (parameters.Count == 4)
                throw new InstructionException("invalid number of parameters");
            if (!parameters[3].IsChar('+'))
                throw new InstructionException("+ expected");
            adder = compiler.CalculateExpression(parameters[4..]);
        }

        return new InOutInstruction(line, type, regNo, regNo2, (uint)adder);
    }
}
