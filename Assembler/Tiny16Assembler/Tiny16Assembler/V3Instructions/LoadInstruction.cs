using GenericAssembler;

namespace Tiny16Assembler.V3Instructions;

internal sealed class LoadStoreInstructionCreator(uint opCode) : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        if (parameters.Count < 3 || parameters[0].Type != TokenType.Name || !parameters[1].IsChar(',') ||
            !InstructionsHelper.GetRegisterNumber(parameters[0].StringValue, out var registerNumber))
            throw new InstructionException("register, register pointer are expected");
        var start = 2;
        var registerNumber2 = InstructionsHelper.GetRegisterNumberWithOffset(compiler, parameters, ref start, out var offset);
        if (offset is > 127 or < -128)
            throw new InstructionException("load/store offset is out of range");
        var o = (uint)offset & 0xFF;
        if (opCode == InstructionCodes.Lw)
            return new OpCodeInstruction(line, file, lineNo, o, opCode, registerNumber, registerNumber2);
        return new OpCodeInstruction(line, file, lineNo, o, opCode, registerNumber2, registerNumber);
    }
}
