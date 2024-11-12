using GenericAssembler;

namespace Cpu16LiteAssembler.Instructions;

public class IncInstructionCreator: InstructionCreator
{
    private readonly AluImmediateInstructionCreator _aluCreator = new(AluOperations.Add, 1);
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        if (parameters.Count != 1 || parameters[0].Type != TokenType.Name)
            throw new InstructionException("register name expected");
        if (parameters[0].StringValue == "rp")
            return new OpCodeInstruction(line, file, lineNo, InstructionCodes.IncRp);
        return _aluCreator.Create(compiler, line, file, lineNo, parameters);
    }
}

public class DecInstructionCreator: InstructionCreator
{
    private readonly AluImmediateInstructionCreator _aluCreator = new(AluOperations.Add, 0xFFFF);
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        if (parameters.Count != 1 || parameters[0].Type != TokenType.Name)
            throw new InstructionException("register name expected");
        if (parameters[0].StringValue == "rp")
            return new OpCodeInstruction(line, file, lineNo, InstructionCodes.DecRp);
        return _aluCreator.Create(compiler, line, file, lineNo, parameters);
    }
}