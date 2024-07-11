namespace Cpu16Assembler.Instructions;

internal sealed class AluImmediateInstruction : Instruction
{
    private readonly uint _aluOperation, _regNo, _value;
    
    internal AluImmediateInstruction(string line, uint aluOperation, uint regNo, uint value): base(line)
    {
        _aluOperation = aluOperation;
        _regNo = regNo;
        _value = value;
    }
    
    internal override uint BuildCode(ushort labelAddress)
    {
        return _aluOperation | 0x80 | (_regNo << 8) | (_value << 16);
    }
}

internal sealed class AluImmediateInstructionCreator(uint aluOperation, uint value) : InstructionCreator
{
    internal override Instruction Create(ICompiler compiler, string line, List<Token> parameters)
    {
        if (parameters.Count != 1 || parameters[0].Type != TokenType.Name ||
            !GetRegisterNumber(parameters[0].StringValue, out var regNo))
            throw new InstructionException("register name expected");
        return new AluImmediateInstruction(line, aluOperation, regNo, value);
    }
}
