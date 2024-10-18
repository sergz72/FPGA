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
        if (token.Type != TokenType.Name || !InstructionsHelper.GetRegisterNumber(token.StringValue, out var registerNumber))
            throw new InstructionException("register name expected");
        if (!compiler.GetNextToken(parameters, ref start).IsChar(','))
            throw new InstructionException("syntax error");
        var immediate = compiler.CalculateExpression(parameters, ref start);
        InstructionsHelper.ValidateOffset11(immediate);
        var o = (uint)immediate;
        return new OpCodeInstruction(line, file, lineNo, o & 0x1FF, opCode, registerNumber, o >> 9);
    }
}
