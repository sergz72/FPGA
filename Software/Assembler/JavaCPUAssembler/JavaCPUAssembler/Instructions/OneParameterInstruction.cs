using GenericAssembler;

namespace JavaCPUAssembler.Instructions;

internal sealed class OneParameterInstructionCreator(uint opCode) : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        var start = 0;
        var immediate = compiler.CalculateExpression(parameters, ref start);
        return new OpCodeInstruction(line, file, lineNo, opCode, (uint)immediate);
    }
}
