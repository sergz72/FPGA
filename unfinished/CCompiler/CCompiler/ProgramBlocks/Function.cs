namespace CCompiler.ProgramBlocks;

internal sealed class Function : ProgramBlock
{
    private Dictionary<string, DataType> _parameters;
    private bool _noBody;
    
    internal Function(CCompiler compiler): base(compiler)
    {
        _parameters = new Dictionary<string, DataType>();
    }
    
    public override void Compile(string fileName, List<Token> tokens, ref int start)
    {
        ParseParameters(fileName, tokens, ref start);
        CCompiler.CheckEOF(fileName, tokens, start);
        if (tokens[start].IsChar(';'))
        {
            start++;
            _noBody = true;
            return;
        }
        _noBody = false;
        base.Compile(fileName, tokens, ref start);
    }

    private void ParseParameters(string fileName, List<Token> tokens, ref int start)
    {
        var first = true;
        while (start < tokens.Count)
        {
            if (!first && tokens[start].IsChar(','))
                start++;
            else if (tokens[start].IsChar(")"))
            {
                start++;
                return;
            }
            first = false;
            var (dataType, name) = Compiler.ParseDataType(fileName, tokens, ref start);
            CCompiler.CheckEOF(fileName, tokens, start);
            if (dataType.Size == 0 && tokens[start].IsChar(')'))
            {
                start++;
                return;
            }
            if (name == null)
                CCompiler.RaiseException(fileName, "name expected", tokens, start);
            _parameters.Add(name, dataType);
        }
        CCompiler.RaiseUnexpectedEOFException(fileName, tokens);
    }
}
