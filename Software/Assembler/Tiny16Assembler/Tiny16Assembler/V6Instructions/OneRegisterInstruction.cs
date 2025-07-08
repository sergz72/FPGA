using GenericAssembler;

namespace Tiny16Assembler.V6Instructions;

internal sealed class OneRegisterInstructionCreator(uint opCode, bool useSrc) : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        if (parameters.Count != 1 || parameters[0].Type != TokenType.Name ||
            !GetRegisterNumber(compiler, parameters[0].StringValue, out var registerNumber))
            throw new InstructionException("register name expected");
        return new OpCode7Instruction(line, file, lineNo, opCode, useSrc ? registerNumber : 0, useSrc ? 0 : registerNumber);
    }
}
