using GenericAssembler;

namespace Tiny16Assembler.V2Instructions;

internal sealed class AluImmediateInstruction : Instruction
{
    private readonly uint _aluOperation, _regNo, _value;
    
    internal AluImmediateInstruction(string line, string file, int lineNo, uint aluOperation, uint regNo, uint value):
        base(line, file, lineNo)
    {
        _aluOperation = aluOperation;
        _regNo = regNo;
        _value = value;
    }
    
    public override uint[] BuildCode(uint labelAddress, uint pc)
    {
        //return [_aluOperation | 0x80 | (_regNo << 8) | (_value << 16)];
        throw new NotImplementedException();
    }
}

internal sealed class AluImmediateInstructionCreator(uint aluOperation, uint value) : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        if (parameters.Count != 1 || parameters[0].Type != TokenType.Name ||
            !GetRegisterNumber(compiler, parameters[0].StringValue, out var regNo))
            throw new InstructionException("register name expected");
        return new AluImmediateInstruction(line, file, lineNo, aluOperation, regNo, value);
    }
}
