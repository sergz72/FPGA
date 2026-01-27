using GenericAssembler;

namespace Tiny16Assembler.V8Instructions;

internal sealed class JmpInstruction : Instruction
{
    private readonly uint _opCode;
    
    internal JmpInstruction(string line, string file, int lineNo, uint opCode, string label): base(line, file, lineNo)
    {
        _opCode = opCode;
        RequiredLabel = label;
        Size = 3;
    }
    
    public override uint[] BuildCode(uint labelAddress, uint pc)
    {
        return [_opCode, labelAddress & 0xFF, labelAddress >> 8];
    }
}

internal sealed class JmpInstructionCreator(uint opCode) : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        if (parameters.Count != 1 || parameters[0].Type != TokenType.Name)
            throw new InstructionException("label name expected");
        return new JmpInstruction(line, file, lineNo, opCode, parameters[0].StringValue);
    }
}