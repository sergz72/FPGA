using GenericAssembler;

namespace JavaCPUAssembler.Instructions;

internal sealed class TwoParametersInstructionCreator(uint opCode) : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        var start = 0;
        var immediate = compiler.CalculateExpression(parameters, ref start);
        if (start > parameters.Count - 2 || !parameters[start++].IsChar(','))
            throw new InstructionException(", and second parameter are expected");
        var immediate2 = compiler.CalculateExpression(parameters, ref start);
        return new OpCodesInstruction(line, file, lineNo, (opCode << 8) | (uint)immediate, (uint)(immediate2 & 0xFFFF));
    }
}