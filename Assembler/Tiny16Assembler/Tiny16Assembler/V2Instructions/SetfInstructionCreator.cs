using GenericAssembler;

namespace Tiny16Assembler.V2Instructions;

public class SetfImmediateInstructionCreator(uint v): InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        //return new AluImmediateInstruction(line, AluOperations.Setf, 0, v);
        throw new NotImplementedException();
    }
}

public class SetfRegisterInstructionCreator: InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        if (parameters.Count != 1 || parameters[0].Type != TokenType.Name ||
            !GetRegisterNumber(compiler, parameters[0].StringValue, out var regNo))
            throw new InstructionException("register name expected");
        //return new AluRegisterInstruction(line, 0x60, AluOperations.Setf, 0, 0, regNo);
        throw new NotImplementedException();
    }
}