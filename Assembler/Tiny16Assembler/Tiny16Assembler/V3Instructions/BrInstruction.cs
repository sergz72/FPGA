using GenericAssembler;

namespace Tiny16Assembler.V3Instructions;

internal sealed class BrInstruction: Instruction
{
    private readonly uint _condition;
    
    internal BrInstruction(string line, string file, int lineNo, uint condition, string label) : base(line, file, lineNo)
    {
        _condition = condition;
        RequiredLabel = label;
    }

    public override uint[] BuildCode(uint labelAddress, uint pc)
    {
        var offset = (int)labelAddress - (int)pc;
        if (offset is > 127 or < -128)
            throw new InstructionException($"{File}:{LineNo}: br offset is out of range");
        return [(InstructionCodes.Br << 4) | (((uint)offset & 0xFF) << 8) | _condition];
    }
}

internal sealed class BrInstructionCreator(uint condition) : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        if (parameters.Count != 1 || parameters[0].Type != TokenType.Name)
            throw new InstructionException("label name expected");
        return new BrInstruction(line, file, lineNo, condition, parameters[0].StringValue);
    }
}