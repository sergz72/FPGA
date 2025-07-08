using GenericAssembler;

namespace Tiny16Assembler.V6Instructions;

internal sealed class TwoRegistersInstructionCreator(uint opCode, bool useSrc) : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        if (parameters.Count != 3 || !parameters[1].IsChar(',') ||
            parameters[0].Type != TokenType.Name || parameters[2].Type != TokenType.Name ||
            !GetRegisterNumber(compiler, parameters[0].StringValue, out var registerNumber1) ||
            !GetRegisterNumber(compiler, parameters[2].StringValue, out var registerNumber2))
            throw new InstructionException("register names expected");
        return new OpCode7Instruction(line, file, lineNo, opCode, useSrc ? registerNumber1 : registerNumber2,
            useSrc ? registerNumber2 : registerNumber1);
    }
}
