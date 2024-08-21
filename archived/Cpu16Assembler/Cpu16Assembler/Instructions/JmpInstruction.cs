using GenericAssembler;

namespace Cpu16Assembler.Instructions;

internal sealed class JmpInstruction : Instruction
{
    private readonly uint _type, _regNo;
    
    internal JmpInstruction(string line, uint type, uint regNo, string? label): base(line)
    {
        _type = type;
        _regNo = regNo;
        RequiredLabel = label;
    }
    
    public override uint BuildCode(ushort labelAddress)
    {
        return _type | (_regNo << 8) | ((uint)labelAddress << 16);
    }
}

internal sealed class JmpInstructionCreator(uint addrCode, uint regCode) : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, List<Token> parameters)
    {
        if ((parameters.Count != 1 && parameters.Count != 3) || parameters[0].Type != TokenType.Name)
            throw new InstructionException("label name and/or register name expected");
        if (GetRegisterNumber(compiler, parameters[0].StringValue, out var regNo))
        {
            string? labelName = null;
            
            if (parameters.Count > 1)
            {
                if (!parameters[1].IsChar(','))
                    throw new InstructionException(", expected");
                if (parameters[2].Type != TokenType.Name)
                    throw new InstructionException("label name expected");
                labelName = parameters[2].StringValue;
            }
            return new JmpInstruction(line, regCode, regNo, labelName);
        }
        return new JmpInstruction(line, addrCode, 0, parameters[0].StringValue);
    }
}
