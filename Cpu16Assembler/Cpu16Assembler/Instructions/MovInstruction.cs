namespace Cpu16Assembler.Instructions;

internal sealed class MovInstruction : Instruction
{
    private readonly uint _type, _regNo, _value2;
    
    internal MovInstruction(uint type, uint regNo, uint value2)
    {
        _type = type;
        _regNo = regNo;
        _value2 = value2;
    }
    
    internal override uint BuildCode(ushort labelAddress)
    {
        return _type | (_regNo << 8) | ((uint)labelAddress << 16);
    }
}

internal sealed class MovInstructionCreator(uint addrCode, uint regCode) : InstructionCreator
{
    internal override Instruction Create(ICompiler compiler, List<Token> parameters)
    {
        if (parameters.Count < 3 || parameters[0].Type != TokenType.Name)
            throw new ParserException("register name and register/immediate expected");
        if (!GetRegisterNumber(parameters[0].StringValue, out var regNo))
            throw new ParserException("register name expected");
        if (!parameters[1].IsChar(','))
            throw new ParserException(", expected");
        if (parameters.Count == 3 && GetRegisterNumber(parameters[2].StringValue, out var regNo2))
            return new MovInstruction(InstructionCodes.MovReg, regNo, regNo2);
        var value2 = compiler.CalculateExpression(parameters[1..]);
        return new MovInstruction(InstructionCodes.MovReg, regNo, (uint)value2);
    }
}
