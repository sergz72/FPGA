using GenericAssembler;

namespace Tiny16Assembler.V3Instructions;

internal sealed class JmpInstruction : Instruction
{
    internal JmpInstruction(string line, string file, int lineNo, string label): base(line, file, lineNo)
    {
        RequiredLabel = label;
    }
    
    public override uint[] BuildCode(uint labelAddress, uint pc)
    {
        var offset = (int)labelAddress - (int)pc;
        if (offset is > 4095 or < -4096)
            throw new InstructionException($"{File}:{LineNo}: jmp offset is out of range");
        var o = (uint)offset & 0x1FFF;
        return [(InstructionCodes.Jmp << 4) | ((o & 0x1FF) << 7) | (o >> 9)];
    }
}

internal sealed class JmpInstructionCreator : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        if (parameters.Count != 1 || parameters[0].Type != TokenType.Name)
            throw new InstructionException("label name expected");
        return new JmpInstruction(line, file, lineNo, parameters[0].StringValue);
    }
}

internal sealed class Jmp16InstructionCreator : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        if (parameters.Count != 1 || parameters[0].Type != TokenType.Name)
            throw new InstructionException("label name expected");
        return new LoadAddressInstruction(line, file, lineNo, InstructionCodes.Jmp16, 0, parameters[2].StringValue);
    }
}
