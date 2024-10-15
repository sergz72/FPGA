using GenericAssembler;

namespace Tiny16Assembler.V3Instructions;

internal sealed class LoadPCInstruction(string line, string file, int lineNo, uint regNo, uint offset) :
    Instruction(line, file, lineNo)
{
    public override uint[] BuildCode(uint labelAddress, uint pc)
    {
        return [(InstructionCodes.Loadpc << 4) | regNo | (offset << 8)];
    }
}

internal sealed class LoadPCInstructionCreator : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        var start = 0;
        var registerNumber = InstructionsHelper.GetRegisterNumberWithOffset(compiler, parameters, ref start, out var offset);
        if (offset is > 127 or < -128)
            throw new InstructionException("ret offset is out of range.");
        var o = (uint)offset & 0xFF;
        return new LoadPCInstruction(line, file, lineNo, registerNumber, o);
    }
}
