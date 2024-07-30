using GenericAssembler;

namespace Cpu16Assembler.Instructions;

internal sealed class MovInstruction : Instruction
{
    private readonly uint _type, _regNo, _value2, _adder;
    
    internal MovInstruction(string line, uint type, uint regNo, uint value2, uint adder): base(line)
    {
        _type = type;
        _regNo = regNo;
        _value2 = value2;
        _adder = adder;
    }
    
    public override uint BuildCode(ushort labelAddress)
    {
        if (_type == InstructionCodes.MovImmediate)
            return _type | (_regNo << 8) | (_value2 << 16);
        else
            return _type | (_regNo << 8) | (_value2 << 16) | (_adder << 24);
    }
}

internal sealed class MovInstructionCreator() : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, List<Token> parameters)
    {
        if (parameters.Count < 3 || parameters[0].Type != TokenType.Name)
            throw new InstructionException("register name and register/immediate expected");
        if (!GetRegisterNumber(parameters[0].StringValue, out var regNo))
            throw new InstructionException("register name expected");
        if (!parameters[1].IsChar(','))
            throw new InstructionException(", expected");
        if (GetRegisterNumber(parameters[2].StringValue, out var regNo2))
        {
            var adder = 0;
            if (parameters.Count > 3)
            {
                if (parameters.Count == 4)
                    throw new InstructionException("invalid number of parameters");
                if (!parameters[3].IsChar('+'))
                    throw new InstructionException("+ expected");
                adder = compiler.CalculateExpression(parameters[4..]);
            }

            return new MovInstruction(line, InstructionCodes.MovReg, regNo, regNo2, (uint)adder);
        }

        var value2 = compiler.CalculateExpression(parameters[2..]);
        return new MovInstruction(line, InstructionCodes.MovImmediate, regNo, (uint)value2, 0);
    }
}
