namespace CCompiler.ProgramBlocks;

public class Call: IProgramBlock
{
    internal readonly string FunctionName;
    internal readonly List<Expression> Parameters;

    internal Call(string functionName)
    {
        FunctionName = functionName;
    }
    
    public void Compile(string fileName, List<Token> tokens, ref int start)
    {
        throw new NotImplementedException();
    }

    public Variable? GetVariable(string name)
    {
        throw new NotImplementedException();
    }

    public List<ExpressionParser.OutputItem> CalculateExpression(string fileName, List<Token> tokens, ref int start)
    {
        throw new NotImplementedException();
    }
}