using GenericAssembler;

namespace Tiny16Assembler.V3Instructions;

internal sealed class LoadPCInstruction(string line, string file, int lineNo, uint regNo, uint offset) :
    Instruction(line, file, lineNo)
{
    public override uint[] BuildCode(uint labelAddress, uint pc)
    {
        return [(InstructionCodes.Loadpc << 4) | regNo | (offset << 7)];
    }
}

internal sealed class LoadPCInstructionCreator : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        var start = 0;
        var registerNumber = InstructionsHelper.GetRegisterNumberWithOffset(compiler, parameters, ref start, out var offset);
        InstructionsHelper.ValidateOffset9(offset);
        var o = (uint)offset & 0x1FF;
        return new LoadPCInstruction(line, file, lineNo, registerNumber, o);
    }
}
