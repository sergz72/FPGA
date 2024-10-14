using GenericAssembler;

namespace Tiny16Assembler.V3Instructions;

internal sealed class CallInstruction(string line, string file, int lineNo, string label) : Instruction(line, file, lineNo)
{
    public override uint[] BuildCode(uint labelAddress, uint pc)
    {
        var offset = (int)labelAddress - (int)pc;
        if (offset is > 511 or < -512)
            throw new InstructionException($"{File}:{LineNo}: call offset is out of range");
        var o = (uint)offset & 0x3FF;
        return [(InstructionCodes.Call << 4) | ((o & 0xFF) << 8) | (o >> 8)];
    }
}

internal sealed class CallInstructionCreator() : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        if (parameters.Count != 1 || parameters[0].Type != TokenType.Name)
            throw new InstructionException("label name expected");
        return new CallInstruction(line, file, lineNo, parameters[0].StringValue);
    }
}
