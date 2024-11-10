using GenericAssembler;

namespace Tiny16Assembler.V3Instructions;

internal sealed class SingleRegisterInstructionCreator(uint opCode, uint hiByte, uint parameter2) : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        if (parameters.Count != 1 || parameters[0].Type != TokenType.Name ||
            !InstructionsHelper.GetRegisterNumber(parameters[0].StringValue, out var registerNumber))
            throw new InstructionException("register name expected");
        return new OpCodeInstruction(line, file, lineNo, hiByte, opCode, registerNumber, parameter2);
    }
}
