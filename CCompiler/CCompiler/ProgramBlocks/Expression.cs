namespace CCompiler.ProgramBlocks;

internal sealed class Expression : IProgramBlock
{
    internal readonly int DerefsCount;
    internal readonly Variable Variable;
    internal readonly List<Token> Value;
    internal readonly string Op;
    
    internal Expression(int derefsCount, Variable variable, string op, List<Token> value)
    {
        DerefsCount = derefsCount;
        Variable = variable;
        Value = value;
        Op = op;
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
