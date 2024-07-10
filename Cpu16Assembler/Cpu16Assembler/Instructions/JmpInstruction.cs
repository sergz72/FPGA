namespace Cpu16Assembler.Instructions;

internal sealed class JmpInstruction : Instruction
{
    private readonly uint _type, _regNo;
    
    internal JmpInstruction(uint type, uint regNo, string? label)
    {
        _type = type;
        _regNo = regNo;
        RequiredLabel = label;
    }
    
    internal override uint BuildCode(ushort labelAddress)
    {
        return _type | (_regNo << 8) | ((uint)labelAddress << 16);
    }
}

internal sealed class JmpInstructionCreator(uint addrCode, uint regCode) : InstructionCreator
{
    internal override Instruction Create(ICompiler compiler, List<Token> parameters)
    {
        if ((parameters.Count != 1 && parameters.Count != 3) || parameters[0].Type != TokenType.Name)
            throw new ParserException("label name and/or register name expected");
        if (GetRegisterNumber(parameters[0].StringValue, out var regNo))
        {
            string? labelName = null;
            
            if (parameters.Count > 1)
            {
                if (!parameters[1].IsChar(','))
                    throw new ParserException(", expected");
                if (parameters[2].Type != TokenType.Name)
                    throw new ParserException("label name expected");
                labelName = parameters[2].StringValue;
            }
            return new JmpInstruction(regCode, regNo, labelName);
        }
        return new JmpInstruction(addrCode, 0, parameters[0].StringValue);
    }
}
