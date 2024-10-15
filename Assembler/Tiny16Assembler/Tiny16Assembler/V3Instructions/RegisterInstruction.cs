using GenericAssembler;

namespace Tiny16Assembler.V3Instructions;

internal sealed class RegisterInstructionCreator(uint opCode, uint hiByte) : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        if (parameters.Count != 3 || !parameters[1].IsChar(',') || parameters[0].Type != TokenType.Name ||
            parameters[2].Type != TokenType.Name ||
            !InstructionsHelper.GetRegisterNumber(parameters[0].StringValue, out var registerNumber1) ||
            !InstructionsHelper.GetRegisterNumber(parameters[2].StringValue, out var registerNumber2))
            throw new InstructionException("register, register are expected");
        return new OpCodeInstruction(line, file, lineNo, hiByte, opCode, registerNumber1, registerNumber2);
    }
}
