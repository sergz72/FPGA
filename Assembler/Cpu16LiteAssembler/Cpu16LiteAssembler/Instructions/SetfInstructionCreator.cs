using GenericAssembler;

namespace Cpu16LiteAssembler.Instructions;

public class SetfImmediateInstructionCreator(uint v): InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        return new AluImmediateInstruction(line, file, lineNo, AluOperations.Setf, 0, v);
    }
}

public class SetfRegisterInstructionCreator: InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        if (parameters.Count != 1 || parameters[0].Type != TokenType.Name ||
            !GetRegisterNumber(compiler, parameters[0].StringValue, out var regNo))
            throw new InstructionException("register name expected");
        return new AluRegisterInstruction(line, file, lineNo, 0x60, AluOperations.Setf, 0, 0, regNo);
    }
}