namespace CCompiler.ProgramBlocks;

public interface IProgramBlock
{
    void Compile(string fileName, List<Token> tokens, ref int start);
    Variable? GetVariable(string name);
    List<ExpressionParser.OutputItem> CalculateExpression(string fileName, List<Token> tokens, ref int start);
}

internal class ProgramBlock : IProgramBlock
{
    internal readonly Dictionary<string, Variable> Variables;
    protected readonly CCompiler Compiler;
    internal readonly List<IProgramBlock> ProgramBlocks;

    internal ProgramBlock(CCompiler compiler)
    {
        Variables = new Dictionary<string, Variable>();
        Compiler = compiler;
        ProgramBlocks = [];
    }
    
    public virtual void Compile(string fileName, List<Token> tokens, ref int start)
    {
        CCompiler.CheckEOF(fileName, tokens, start);
        if (!tokens[start].IsChar("{"))
            CCompiler.RaiseUnexpectedTokenException(tokens[start]);
        start++;
        while (start < tokens.Count)
        {
            var token = tokens[start];
            if (token.IsChar("}"))
            {
                start++;
                return;
            }

            if (token.Type == TokenType.Name)
            {
                switch (token.StringValue)
                {
                    case "if":
                        start++;
                        ParseIfBlock(fileName, tokens, ref start);
                        break;
                    case "for":
                        start++;
                        ParseForBlock(fileName, tokens, ref start);
                        break;
                    case "do":
                        start++;
                        ParseDoBlock(fileName, tokens, ref start);
                        break;
                    case "while":
                        start++;
                        ParseWhileBlock(fileName, tokens, ref start);
                        break;
                    case "switch":
                        start++;
                        ParseSwitchBlock(fileName, tokens, ref start);
                        break;
                    case "return":
                        start++;
                        ParseReturn(fileName, tokens, ref start);
                        break;
                    default:
                        if (IsDataTypeDeclarationStart(token))
                            ParseVariableDeclaration(fileName, tokens, ref start);
                        else if (!ParseFunctionCall(fileName, tokens, ref start))
                            ParseStatement(fileName, tokens, ref start);
                        break;
                }
            }
            else
                CCompiler.RaiseUnexpectedTokenException(token);
        }
        CCompiler.RaiseUnexpectedEOFException(fileName, tokens);
    }

    private void ParseReturn(string fileName, List<Token> tokens, ref int start)
    {
        throw new NotImplementedException();
    }

    private void ParseSwitchBlock(string fileName, List<Token> tokens, ref int start)
    {
        throw new NotImplementedException();
    }

    private void ParseWhileBlock(string fileName, List<Token> tokens, ref int start)
    {
        throw new NotImplementedException();
    }

    private void ParseDoBlock(string fileName, List<Token> tokens, ref int start)
    {
        throw new NotImplementedException();
    }

    private void ParseForBlock(string fileName, List<Token> tokens, ref int start)
    {
        CCompiler.CheckEOF(fileName, tokens, start);
        if (!tokens[start++].IsChar("("))
            CCompiler.RaiseException(fileName, "( expected", tokens, start);
        var expression = CCompiler.ParseExpression(fileName, tokens, ref start, ')');
        start++;
        CCompiler.CheckEOF(fileName, tokens, start);
        if (tokens[start].IsChar("{"))
        {
            var pb = new ProgramBlock(Compiler);
            pb.Compile(fileName, tokens, ref start);
        }
        else
        {
            if (!ParseFunctionCall(fileName, tokens, ref start))
                ParseStatement(fileName, tokens, ref start);
        }
    }

    private void ParseIfBlock(string fileName, List<Token> tokens, ref int start)
    {
        throw new NotImplementedException();
    }

    private bool ParseFunctionCall(string fileName, List<Token> tokens, ref int start)
    {
        return false;
    }

    private void ParseStatement(string fileName, List<Token> tokens, ref int start)
    {
        var token = tokens[start];
        var derefsCount = 0;
        while (token.IsChar("*"))
        {
            derefsCount++;
            start++;
            CCompiler.CheckEOF(fileName, tokens, start);
            token = tokens[start];
        }
        if (token.Type == TokenType.Name)
        {
            var variable = GetVariable(token.StringValue);
            if (variable == null)
                CCompiler.RaiseException(fileName, $"Variable {token.StringValue} not found.", tokens, start);
            start++;
            CCompiler.CheckEOF(fileName, tokens, start);
            if (tokens[start].Type != TokenType.Symbol || !IsAssignOperator(tokens[start].StringValue))
                CCompiler.RaiseUnexpectedTokenException(tokens[start]);
            var op = tokens[start++].StringValue; 
            var value = CCompiler.ParseExpression(fileName, tokens, ref start, ';');
            start++;
            ProgramBlocks.Add(new Expression(derefsCount, variable, op, value));
        }
        else
            CCompiler.RaiseUnexpectedTokenException(token);
    }

    private static bool IsAssignOperator(string op)
    {
        return op is "=" or "+=" or "-=" or "*=" or "/=" or "%=" or "^=" or "&=" or "|=" or "<<=" or ">>=";
    }

    private void ParseVariableDeclaration(string fileName, List<Token> tokens, ref int start)
    {
        var (dataType, name) = Compiler.ParseDataType(fileName, tokens, ref start);
        if (name == null)
            CCompiler.RaiseException(fileName, "name expected", tokens, start);
        CCompiler.CheckEOF(fileName, tokens, start);
        while (start < tokens.Count)
        {
            var token = tokens[start++];
            var variable = new Variable(name, dataType);
            AddVariable(name, token, variable);
            if (token.IsChar(';'))
                return;
l1:         if (token.IsChar(','))
            {

                CCompiler.CheckEOF(fileName, tokens, start);
                if (tokens[start].Type != TokenType.Name)
                    CCompiler.RaiseException(fileName, "name expected", tokens, start);
                name = tokens[start++].StringValue;
                continue;
            }
            if (!token.IsChar("="))
                CCompiler.RaiseUnexpectedTokenException(token);
            var value = CCompiler.ParseExpression(fileName, tokens, ref start, ';', ',');
            ProgramBlocks.Add(new Expression(0, variable, "=", value));
            token = tokens[start++];
            if (token.IsChar(','))
                goto l1;
            break;
        }
    }

    private void AddVariable(string name, Token start, Variable variable)
    {
        if (!Variables.TryAdd(name, variable))
            CCompiler.RaiseException($"Variable with name {name} is already defined", start);
    }
    
    private static bool IsDataTypeDeclarationStart(Token token)
    {
        return token is { Type: TokenType.Name, StringValue: "unsigned" or "int" or "short" or "long" or "void" or "static"};
    }

    public Variable? GetVariable(string name)
    {
        if (Variables.TryGetValue(name, out var variable) || Compiler.Variables.TryGetValue(name, out variable))
            return variable;
        return null;
    }

    public List<ExpressionParser.OutputItem> CalculateExpression(string fileName, List<Token> tokens, ref int start)
    {
        var parser = new ExpressionParser(this, 256);
        return parser.Parse(fileName, tokens, ref start);
    }
}
