using System.Reflection.Emit;
using GenericAssembler;

namespace Tiny16Assembler.V3Instructions;

internal sealed class JalInstruction: Instruction
{
    private readonly uint _registerNumber;
    internal JalInstruction(string line, string file, int lineNo, uint registerNumber, string label) :
        base(line, file, lineNo)
    {
        RequiredLabel = label;
        _registerNumber = registerNumber;
    }

    public override uint[] BuildCode(uint labelAddress, uint pc)
    {
        var offset = (int)labelAddress - (int)pc;
        if (offset is > 511 or < -512)
            throw new InstructionException($"{File}:{LineNo}: jal offset is out of range");
        var o = (uint)offset & 0x3FF;
        return [(InstructionCodes.Jal << 4) | ((o & 0xFF) << 8) | (_registerNumber << 2) | (o >> 8)];
    }
}

internal sealed class JalInstructionCreator : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        if (parameters.Count < 3 || !parameters[1].IsChar(',') || parameters[0].Type != TokenType.Name ||
            parameters[2].Type != TokenType.Name ||
            !InstructionsHelper.GetRegisterNumber(parameters[0].StringValue, out var registerNumber))
            throw new InstructionException("register, label name are expected");
        return new JalInstruction(line, file, lineNo, registerNumber, parameters[2].StringValue);
    }
}
