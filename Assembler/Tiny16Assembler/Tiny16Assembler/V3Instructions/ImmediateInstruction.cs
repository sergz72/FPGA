using GenericAssembler;

namespace Tiny16Assembler.V3Instructions;

internal sealed class ImmediateInstructionCreator(uint opCode) : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        if (parameters.Count < 3)
            throw new InstructionException("register, immediate are expected");
        var start = 0;
        var token = compiler.GetNextToken(parameters, ref start);
        if (token.Type != TokenType.Name)
            throw new InstructionException("register name expected");
        var registerNumber = InstructionsHelper.GetRegisterNumber(token.StringValue);
        if (!compiler.GetNextToken(parameters, ref start).IsChar(','))
            throw new InstructionException("syntax error");
        var immediate = compiler.CalculateExpression(parameters, ref start);
        InstructionsHelper.ValidateOffset(immediate);
        var o = (uint)(immediate & 0x3FF);
        return new OpCodeInstruction(line, file, lineNo, o & 0xFF, opCode, registerNumber, o >> 8);
    }
}
