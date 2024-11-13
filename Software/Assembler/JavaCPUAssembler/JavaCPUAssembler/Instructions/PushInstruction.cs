using GenericAssembler;

namespace JavaCPUAssembler.Instructions;

internal sealed class PushInstructionCreator : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        var start = 0;
        var immediate = compiler.CalculateExpression(parameters, ref start);
        return new OpCodesInstruction(line, file, lineNo, InstructionCodes.Push << 8,
            (uint)(immediate & 0xFFFF),
            (uint)((immediate >> 16) & 0xFFFF));
    }
}

internal sealed class PushLongInstructionCreator : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        var start = 0;
        var immediate = compiler.CalculateExpression(parameters, ref start);
        return new OpCodesInstruction(line, file, lineNo, InstructionCodes.PushLong << 8,
            (uint)(immediate & 0xFFFF),
            (uint)((immediate >> 16) & 0xFFFF),
            (uint)((immediate >> 32) & 0xFFFF),
            (uint)((immediate >> 48) & 0xFFFF));
    }
}

internal sealed class PushShortInstructionCreator : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        var start = 0;
        var immediate = compiler.CalculateExpression(parameters, ref start);
        return new OpCodesInstruction(line, file, lineNo, InstructionCodes.SPush << 8, (uint)(immediate & 0xFFFF));
    }
}
