namespace Cpu16Assembler.Instructions;

internal sealed class RegisterLoadInstructionCreator(uint adder) : InstructionCreator
{
    internal override Instruction Create(ICompiler compiler, string line, List<Token> parameters)
    {
        if (parameters.Count != 1 || parameters[0].Type != TokenType.Name ||
            !GetRegisterNumber(parameters[0].StringValue, out var regNo))
            throw new InstructionException("register name expected");
        return new MovInstruction(line, InstructionCodes.MovImmediate, regNo, adder, 0);
    }
}
