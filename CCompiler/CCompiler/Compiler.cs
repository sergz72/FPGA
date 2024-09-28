using System.Diagnostics.CodeAnalysis;
using CCompiler.ProgramBlocks;

namespace CCompiler;

public sealed class CCompiler: IProgramBlock
{
    internal sealed class CompilerException(string fileName, int lineNo, int startChar, string message) :
        Exception($"Error in {fileName}:{lineNo}:{startChar} {message}")
    {
        internal CompilerException(string fileName, List<Token> tokens, int idx, string message):
            this(fileName, idx == tokens.Count ? (tokens.Count == 0 ? 1 : tokens[idx - 1].Line) : tokens[idx].Line,
                idx == tokens.Count ? (tokens.Count == 0 ? 1 : tokens[idx - 1].StartChar) : tokens[idx].StartChar, message)
        {}
        
        internal CompilerException(Token t, string message): this(t.FileName, t.Line, t.StartChar, message)
        {}
    }

    private readonly List<string> _sources;
    private readonly ICpu _cpu;
    public readonly Preprocessor Preprocessor;
    internal readonly Dictionary<string, Function> Functions;
    internal readonly Dictionary<string, Variable> Variables;
    
    internal CCompiler(List<string> sources, Preprocessor preprocessor, string architecture)
    {
        _sources = sources;
        _cpu = BuildCpu(architecture);
        Preprocessor = preprocessor;
        Functions = new Dictionary<string, Function>();
        Variables = new Dictionary<string, Variable>();
    }

    public CCompiler(List<string> sources, Preprocessor preprocessor)
    {
        _sources = sources;
        _cpu = new Cpu16Lite(this);
        Preprocessor = preprocessor;
        Functions = new Dictionary<string, Function>();
        Variables = new Dictionary<string, Variable>();
    }
    
    [DoesNotReturn]
    public static void RaiseException(string errorMessage, Token t)
        => throw new CompilerException(t.FileName, t.Line, t.StartChar, errorMessage);
    [DoesNotReturn]
    internal static void RaiseException(string fileName, string errorMessage, List<Token> tokens, int idx)
        => throw new CompilerException(fileName, tokens, idx, errorMessage);
    [DoesNotReturn]
    internal static void RaiseUnexpectedEOFException(string fileName, List<Token> tokens)
        => throw new CompilerException(fileName, tokens, tokens.Count, "Unexpected end of file");

    [DoesNotReturn]
    internal static void RaiseEndOfStatementExpectedException(string fileName, List<Token> tokens, int start)
        => throw new CompilerException(fileName, tokens, start, "; expected");
    
    internal static void CheckEOF(string fileName, List<Token> tokens, int idx)
    {
        if (idx == tokens.Count)
            RaiseUnexpectedEOFException(fileName, tokens);
    }

    internal static void RaiseUnexpectedTokenException(Token t)
        => throw new CompilerException(t.FileName, t.Line, t.StartChar, $"Unexpected token {t}");

    public void Compile(bool onlyPreprocess)
    {
        var tokens = Preprocessor.Preprocess(_sources, onlyPreprocess);
        if (onlyPreprocess)
            return;
        var syntaxTree = new SyntaxTreeBuilder(tokens).Build();
        /*var start = 0;
        while (start < tokens.Count)
        {
            var token = tokens[start];
            var (dataType, name) = ParseDataType(token.FileName, tokens, ref start);
            if (name == null)
                throw new CompilerException(token.FileName, token.Line, token.StartChar, "name expected");
            CheckEOF(token.FileName, tokens, start);
            token = tokens[start];
            if (token.IsChar('('))
            {
                start++;
                var function = new Function(this);
                function.Compile(token.FileName, tokens, ref start);
                AddFunction(name, token, function);
            }
            else
                AddVariable(name, token, new Variable(name, this, token.FileName, dataType, tokens, ref start));
        }*/
    }

    internal (DataType, string?) ParseDataType(string fileName, List<Token> tokens, ref int start)
    {
        uint? size = null;
        var signed = true;
        var isConstant = false;
        var isStatic = false;
        while (start < tokens.Count && (tokens[start].Type == TokenType.Name || tokens[start].IsChar("...")) && size == null)
        {
            if (tokens[start].IsChar("..."))
            {
                size = uint.MaxValue;
                start++;
                break;
            }
            switch (tokens[start++].StringValue)
            {
                case "static":
                    isStatic = true;
                    break;
                case "const":
                    isConstant = true;
                    break;
                case "unsigned":
                    signed = false;
                    break;
                case "void":
                    size = 0;
                    break;
                case "char":
                case "short":
                    size = 2;
                    break;
                case "int":
                    size = 2;
                    break;
                case "long":
                    size = 4;
                    break;
                default:
                    throw new CompilerException(fileName, tokens, start, "data type expected");
            }
        }
        if (size == null)
            throw new CompilerException(fileName, tokens, start, "data type expected");
        if (size != uint.MaxValue)
        {
            var pointerCount = 0;
            while (start < tokens.Count && tokens[start].IsChar('*'))
            {
                start++;
                pointerCount++;
            }

            string? name = null;
            if (start < tokens.Count && tokens[start].Type == TokenType.Name)
                name = tokens[start++].StringValue;
            return (BuildDataType(fileName, (uint)size, signed, isConstant, isStatic, pointerCount, tokens, ref start), name);
        }
        return (BuildDataType(fileName, (uint)size, signed, isConstant, isStatic, 0, tokens, ref start), "");
    }

    private DataType BuildDataType(string fileName, uint size, bool signed, bool isConstant, bool isStatic,
                                            int pointerCount, List<Token> tokens, ref int start)
    {
        var aSizes = new List<List<Token>>();
        if (start < tokens.Count && tokens[start].IsChar('['))
        {
            start++;
            aSizes = ParseArrayDefinition(fileName, tokens, ref start);
            pointerCount += aSizes.Count;
        }
        if (pointerCount > 0)
        {
            var dt = new DataType(size, signed, false, isStatic, null, 0);
            while (pointerCount-- > 0)
                dt = new DataType(2, false, isConstant, isStatic, dt, 0);
            return dt;
        }
        return new DataType(size, signed, isConstant, isStatic, null, 0);
    }

    private List<List<Token>> ParseArrayDefinition(string fileName, List<Token> tokens, ref int start)
    {
        var result = new List<List<Token>>();
        for (;;)
        {
            CheckEOF(fileName, tokens, start);
            var t = tokens[start++];
            if (t.IsChar(']'))
                result.Add([]);
            else
            {
                var expression = ParseExpression(fileName, tokens, ref start, ']');
                start++;
                result.Add(expression);
            }
            if (start == tokens.Count || !tokens[start].IsChar('['))
                return result;
        }
    }

    private ICpu BuildCpu(string architecture)
    {
        if (architecture == "Cpu16Lite")
            return new Cpu16Lite(this);
        throw new ArgumentException("Unknown architecture");
    }

    private void AddFunction(string name, Token start, Function f)
    {
        if (!Functions.TryAdd(name, f))
            throw new CompilerException(start, $"Function with name {name} is already defined");
    }

    private void AddVariable(string name, Token start, Variable variable)
    {
        if (!Variables.TryAdd(name, variable))
            throw new CompilerException(start, $"Variable with name {name} is already defined");
    }

    public List<string> GenerateCode()
    {
        return _cpu.GenerateCode();
    }

    public void Compile(string fileName, List<Token> tokens, ref int start)
    {
        throw new NotImplementedException();
    }

    public Variable? GetVariable(string name)
    {
        return Variables.GetValueOrDefault(name);
    }
    
    public List<ExpressionParser.OutputItem> CalculateExpression(string fileName, List<Token> tokens, ref int start)
    {
        var parser = new ExpressionParser(this, 256);
        return parser.Parse(fileName, tokens, ref start);
    }
    
    public static List<Token> ParseExpression(string fileName, List<Token> tokens, ref int start, params char[] endChars)
    {
        List<Token> result = [];
        var parenCount = 0;

        while (start < tokens.Count)
        {
            var t = tokens[start];
            if (t is { Type: TokenType.Symbol, StringValue.Length: 1 } && endChars.Contains(t.StringValue[0]) &&
                parenCount == 0)
                return result;
            start++;
            if (t.IsChar('('))
                parenCount++;
            else if (t.IsChar(')'))
                parenCount++;
            result.Add(t);
        }
        
        RaiseUnexpectedEOFException(fileName, tokens);
        return result;
    }

}

internal interface ICpu
{
    List<string> GenerateCode();
}

internal class CPUException(string message): Exception(message)
{}

public record DataType(
    uint Size,
    bool Signed,
    bool IsConstant,
    bool IsStatic,
    DataType? Parent,
    uint Length);

public class Variable
{
    internal readonly DataType Type;
    internal readonly int? Value;
    internal readonly string Name;

    public Variable(string name, DataType type)
    {
        Name = name;
        Type = type;
    }
    
    public Variable(string name, IProgramBlock block, string fileName, DataType type, List<Token> tokens, ref int start)
    {
        Name = name;
        CCompiler.CheckEOF(fileName, tokens, start);
        Type = type;
        var token = tokens[start++];
        if (token.IsChar(';'))
            Value = null;
        else if (token.IsChar('='))
        {
            var expression = block.CalculateExpression(fileName, tokens, ref start);
            Value = ExpressionParser.Calculate(token, expression);
            if (start == tokens.Count || !tokens[start].IsChar(';'))
                CCompiler.RaiseEndOfStatementExpectedException(token.FileName, tokens, start);
            start++;
        }
        else
            CCompiler.RaiseUnexpectedTokenException(token);
    }

    public override string ToString()
    {
        return Name;
    }
}
