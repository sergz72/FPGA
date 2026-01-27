using GenericAssembler;

namespace Tiny16Assembler.V8Instructions;

internal sealed class OneRegisterInstructionCreator(uint opCode) : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        if (parameters.Count != 1 || parameters[0].Type != TokenType.Name ||
            !GetRegisterNumber(compiler, parameters[0].StringValue, out var registerNumber))
            throw new InstructionException("register name expected");
        return new TwoBytesInstruction(line, file, lineNo, opCode, registerNumber);
    }
}