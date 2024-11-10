namespace SZForth;

internal sealed class Preprocessor
{
    private readonly ForthCompiler _compiler;
    private readonly Stack<bool> _skipStack;
    
    internal Preprocessor(ForthCompiler compiler)
    {
        _compiler = compiler;
        _skipStack = new();
    }
    
    internal bool Process(Token token)
    {
        if (token.Type == TokenType.Word)
        {
            switch (token.Word)
            {
                case "[IF]":
                    _skipStack.Push(_compiler.DataStack.Pop() == 0);
                    return true;
                case "[ELSE]":
                    if (!_skipStack.TryPop(out var skip))
                        throw new CompilerException("unexpected [ELSE]", token);
                    _skipStack.Push(!skip);
                    return true;
                case "[THEN]":
                    if (!_skipStack.TryPop(out var _))
                        throw new CompilerException("unexpected [THEN]", token);
                    return true;
            }
        }
        return _skipStack.TryPeek(out var skipDefault) && skipDefault;
    }

    internal void Finish()
    {
        if (_skipStack.Count != 0)
            throw new CompilerException("unfinished preprocessor directive");
    }
}