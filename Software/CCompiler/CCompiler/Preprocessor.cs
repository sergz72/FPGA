using System.Runtime.CompilerServices;
using System.Text;
using Microsoft.Win32.SafeHandles;

namespace CCompiler;

public sealed class Preprocessor
{
    public record DefineData(List<Token> Tokens, List<string> Parameters)
    {
        public List<Token> Expand(string fileName, List<Token> tokens, ref int start)
        {
            var parameterValues = Preprocessor.ParseDefineParameters(fileName, tokens, ref start);
            if (parameterValues.Count != Parameters.Count)
                CCompiler.RaiseException(fileName, "wrong define parameters count", tokens, start);
            return Expand(parameterValues);
        }

        private List<Token> Expand(List<List<Token>> parameterValues)
        {
            return Tokens.SelectMany(t => Expand(t, parameterValues)).ToList();
        }

        private IEnumerable<Token> Expand(Token token, List<List<Token>> parameterValues)
        {
            if (token.Type == TokenType.Name)
            {
                for (var i = 0; i < Parameters.Count; i++)
                {
                    if (token.StringValue == Parameters[i])
                        return parameterValues[i].Select(tt =>
                            new Token(tt.Type, tt.StringValue, tt.IntValue, tt.FileName, token.Line, token.StartChar));
                }
            }
            return [token];
        }
    }

    private readonly List<string> _includePaths;
    public readonly Dictionary<string, DefineData> Defines;
    public readonly List<Token> Tokens;
    private int _ifLevel;
    
    public Preprocessor(List<string> includePaths, Dictionary<string, string> defines)
    {
        _includePaths = includePaths;
        Defines = BuildDefines(defines);
        Tokens = [];
    }

    private static Dictionary<string, DefineData> BuildDefines(Dictionary<string, string> defines)
    {
        return defines.ToDictionary(d => d.Key, d => BuildDefineData(d.Value));
    }

    private static DefineData BuildDefineData(string value)
    {
        var parser = new CParser("command line", value);
        return new DefineData(parser.Parse(), []);
    }

    private void Preprocess(string fileName, string? code = null, bool print = false)
    {
        if (code == null)
        {
            fileName = Path.GetFullPath(fileName);
            code = File.ReadAllText(fileName);
        }
        var parser = new CParser(fileName, code);
        var tokens = parser.Parse();
        var start = 0;
        _ifLevel = 0;
        while (start < tokens.Count)
        {
            var t = tokens[start++];
            if (t.Type == TokenType.Name)
            {
                if (t.StringValue.StartsWith('#'))
                    Directive(fileName, t.StringValue, tokens, ref start, print);
                else if (Defines.TryGetValue(t.StringValue, out var value))
                {
                    var result = value.Expand(fileName, tokens, ref start);
                    Tokens.AddRange(result);
                    if (print)
                    {
                        foreach (var token in result)
                            token.Print();
                    }
                }
                else
                {
                    Tokens.Add(t);
                    if (print)
                        t.Print();
                }
            }
            else if (t.Type != TokenType.Eol)
            {
                Tokens.Add(t);
                if (print)
                    t.Print();
            }
            else if (print)
                Console.WriteLine();
        }
    }

    internal List<Token> Preprocess(List<string> sources, bool print)
    {
        foreach (var source in sources)
            Preprocess(source, null, print);
        return Tokens;
    }

    private void Directive(string fileName, string name, List<Token> tokens, ref int start, bool print)
    {
        switch (name)
        {
            case "#include":
                Include(fileName, tokens, ref start, print);
                break;
            case "#define":
                Define(fileName, tokens, ref start);
                break;
            case "#ifdef":
                IfDef(fileName, false, tokens, ref start);
                break;
            case "#ifndef":
                IfDef(fileName, true, tokens, ref start);
                break;
            case "#endif":
                if (_ifLevel == 0)
                    CCompiler.RaiseException(fileName, "unexpected #endif", tokens, start - 1);
                break;
            default:
                CCompiler.RaiseException("Unknown preprocessor directive", tokens[start - 1]);
                break;
        }
    }

    private void IfDef(string fileName, bool not, List<Token> tokens, ref int start)
    {
        if (start == tokens.Count || tokens[start].Type != TokenType.Name) 
            CCompiler.RaiseException(fileName, "name expected", tokens, start);
        var name = tokens[start++].StringValue;
        _ifLevel++;
        if (Defines.ContainsKey(name) == not)
            SkipUntilEndifOrElse(fileName, not, tokens, ref start);
    }

    private void SkipUntilEndifOrElse(string fileName, bool not, List<Token> tokens, ref int start)
    {
        var level = _ifLevel;

        while (start < tokens.Count)
        {
            var t = tokens[start++];
            if (t.Type == TokenType.Name)
            {
                switch (t.StringValue)
                {
                    case "#ifdef":
                    case "#ifndef":
                        level++;
                        break;
                    case "#else":
                    case "#endif":
                        if (level == _ifLevel)
                        {
                            if (t.StringValue == "#endif")
                                _ifLevel--;
                            return;
                        }
                        level--;
                        break;
                }
            }
        }
        CCompiler.RaiseUnexpectedEOFException(fileName, tokens);
    }

    private void Define(string fileName, List<Token> tokens, ref int start)
    {
        if (start == tokens.Count || tokens[start].Type != TokenType.Name) 
            CCompiler.RaiseException(fileName, "define name expected", tokens, start);
        var define = tokens[start].StringValue;
        if (Defines.ContainsKey(define))
            CCompiler.RaiseException($"{define} is already defined", tokens[start]);
        start++;
        var parameters = ParseDefineParameters(fileName, tokens, ref start);
        var stringParameters = ParseDefineDeclarationParameters(fileName, parameters);
        var list = new List<Token>();
        var continueToNextLine = false;
        while (start < tokens.Count)
        {
            var token = tokens[start++];
            if (token.Type != TokenType.Eol)
            {
                if (token.IsChar('\\'))
                    continueToNextLine = true;
                else if (token.Type == TokenType.Name)
                {
                    if (!stringParameters.Contains(token.StringValue) &&
                        Defines.TryGetValue(token.StringValue, out var d))
                        list.AddRange(d.Expand(fileName, tokens, ref start));
                    else
                        list.Add(token);
                }
                else
                    list.Add(token);
            }
            else if (!continueToNextLine)
                break;
        }
        Defines.Add(define, new DefineData(list, stringParameters));
    }

    private List<string> ParseDefineDeclarationParameters(string fileName, List<List<Token>> parameters)
    {
        return parameters.Select(l => ParseDefineDeclarationParameter(fileName, l)).ToList();
    }

    private string ParseDefineDeclarationParameter(string fileName, List<Token> tokens)
    {
        if (tokens.Count != 1 || tokens[0].Type != TokenType.Name)
            CCompiler.RaiseException(fileName, "name expected", tokens, 0);
        return tokens[0].StringValue;
    }

    private static List<List<Token>> ParseDefineParameters(string fileName, List<Token> tokens, ref int start)
    {
        var result = new List<List<Token>>();
        if (start < tokens.Count && tokens[start].IsChar('('))
        {
            start++;
            while (start < tokens.Count)
            {
                var expression = CCompiler.ParseExpression(fileName, tokens, ref start, ',', ')');
                result.Add(expression);
                if (tokens[start++].IsChar(')'))
                {
                    if (result.Count == 0)
                        CCompiler.RaiseException("empty define parameters list", tokens[start - 1]);
                    return result;
                }
            }
            CCompiler.RaiseUnexpectedEOFException(fileName, tokens);
        }
        return result;
    }

    private void Include(string fileName, List<Token> tokens, ref int start, bool print)
    {
        CCompiler.CheckEOF(fileName, tokens, start);
        string? includeFileName = null;
        var t = tokens[start++];
        if (t.Type == TokenType.String)
        {
            var dirName = Path.GetDirectoryName(t.FileName);
            if (dirName == null)
                CCompiler.RaiseException(fileName, "null directory name", tokens, start);
            includeFileName = Path.Combine(dirName, t.StringValue);
            if (!File.Exists(includeFileName))
                includeFileName = FindFile(t.StringValue, t);
        }
        else if (t.IsChar('<'))
            includeFileName = BuildIncludeFileName(fileName, tokens, ref start);
        else
            CCompiler.RaiseException(fileName, "file name expected", tokens, start);
        
        Preprocess(includeFileName, null, print);
    }

    private string BuildIncludeFileName(string fileName, List<Token> tokens, ref int start)
    {
        var includeFileName = new StringBuilder();
        while (start < tokens.Count)
        {
            if (tokens[start].IsChar('>'))
            {
                start++;
                return FindFile(includeFileName.ToString(), tokens[start]);
            }
            var t = tokens[start++];
            if (t.StringValue == "")
                CCompiler.RaiseUnexpectedTokenException(t);
            else
                includeFileName.Append(t.StringValue);
        }
        CCompiler.RaiseUnexpectedEOFException(fileName, tokens);
        throw new Exception();
    }

    private string FindFile(string fileName, Token token)
    {
        var path = _includePaths.Select(p =>Path.Combine(p, fileName)).FirstOrDefault(File.Exists);
        if (path == null)
            CCompiler.RaiseException($"File not found {fileName}", token);
        return path;
    }
}