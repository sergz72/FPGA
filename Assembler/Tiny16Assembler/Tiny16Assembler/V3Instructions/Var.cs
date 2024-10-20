using GenericAssembler;

namespace Tiny16Assembler.V3Instructions;

public class VarCreator: InstructionCreator
{
    private const int MinVarAddress = -256;
    private static int _varAddress = -1;
    
    public override Instruction? Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        if (parameters.Count != 1 || parameters[0].Type != TokenType.Name)
            throw new Exception("variable name expected");
        if (_varAddress <= MinVarAddress)
            throw new InstructionException("Too many variables");
        compiler.AddConstant(parameters[0].StringValue, _varAddress--);
        return null;
    }
}