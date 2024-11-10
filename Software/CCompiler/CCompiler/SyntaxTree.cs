namespace CCompiler;

public enum SyntaxTreeType
{
    VariableDeclaration,
    FunctionDeclaration,
    Statement,
    ForBlock,
    FunctionCall,
    IfBlock
}

public record SyntaxTree(SyntaxTreeType Type, SyntaxTree? Left, SyntaxTree? Right, List<Token> Tokens);

public sealed class SyntaxTreeBuilder
{
    private readonly List<Token> _tokens;
    
    public SyntaxTreeBuilder(List<Token> tokens)
    {
        _tokens = tokens;
    }
    
    public SyntaxTree Build()
    {
        var start = 0;
        while (start < _tokens.Count)
        {
            var token = _tokens[start];
            var (dataType, name) = ParseDataType(token.FileName, _tokens, ref start);
            if (name == null)
                throw new CCompiler.CompilerException(token.FileName, token.Line, token.StartChar, "name expected");
            CCompiler.CheckEOF(token.FileName, _tokens, start);
            token = _tokens[start];
            if (token.IsChar('('))
            {
                start++;
                var function = new Function(this);
                function.Compile(token.FileName, tokens, ref start);
                AddFunction(name, token, function);
            }
            else
                AddVariable(name, token, new Variable(name, this, token.FileName, dataType, _tokens, ref start));
        }
        return new SyntaxTree(SyntaxTreeType.Statement, null, null, []);
    }
}
