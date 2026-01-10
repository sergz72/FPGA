using GenericAssembler;

namespace Tiny16Assembler.V7Instructions;

internal sealed class JmpInstruction : Instruction
{
    internal JmpInstruction(string line, string file, int lineNo, string label): base(line, file, lineNo)
    {
        RequiredLabel = label;
        Size = 3;
    }
    
    public override uint[] BuildCode(uint labelAddress, uint pc)
    {
        return [InstructionCodes.Jmp, labelAddress & 0xFF, labelAddress >> 8];
    }
}

internal sealed class JmpInstructionCreator() : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        if (parameters.Count != 1 || parameters[0].Type != TokenType.Name)
            throw new InstructionException("label name expected");
        return new JmpInstruction(line, file, lineNo, parameters[0].StringValue);
    }
}