using CCompiler.ProgramBlocks;

namespace CCompiler;

public sealed class ExpressionParser
{
    public class OutputItem
    {
        internal readonly string? Op;
        internal int? Value;
        internal readonly Variable? Var;
        internal readonly Token T;

        internal OutputItem(string? op, int? value, Variable? var, Token token)
        {
            Op = op;
            Value = value;
            Var = var;
            T = token;
        }
    }

    private static readonly Dictionary<string, int> Priorities = new()
    {
        { "*", 7 },
        { "/", 7 },
        
        { "+", 6 },
        { "-", 6 },

        { "<<", 5 },
        { ">>", 5 },

        { ">=", 4 },
        { "<=", 4 },
        { ">", 4 },
        { "<", 4 },
        { "==", 4 },
        { "!=", 4 },
        
        { "~", 3 },
        
        { "&", 2 },
        { "^", 2 },
        { "|", 2 },
        
        { "||", 1 },
        { "&&", 1 }
    };

    private static readonly HashSet<string> AllowedSymbols;
    private readonly IProgramBlock _programBlock;
    
    private readonly OutputItem[] _output;
    private int _outputPointer;
    
    private bool _prevOp;

    private readonly string[] _opStack;
    private int _opStackPointer;

    static ExpressionParser()
    {
        AllowedSymbols = Priorities.Select(p => p.Key).ToHashSet();
        AllowedSymbols.Add("(");
        AllowedSymbols.Add(")");
    }
    
    internal ExpressionParser(IProgramBlock block, int stackSize)
    {
        _programBlock = block;
        _output = new OutputItem[stackSize];
        _opStack = new string[stackSize];
    }

    internal List<OutputItem> Parse(string fileName, List<Token> tokens, ref int start)
    {
        var bracketCounter = 0;

        while (start < tokens.Count)
        {
            var token = tokens[start];
            switch (token.Type)
            {
                case TokenType.Name:
                    start++;
                    ProcessName(token);
                    break;
                case TokenType.Number:
                    start++;
                    ProcessNumber(token);
                    break;
                case TokenType.Symbol:
                    if (AllowedSymbols.Contains(token.StringValue))
                    {
                        if (token.StringValue == "(")
                            bracketCounter++;
                        else if (token.StringValue == ")")
                        {
                            if (bracketCounter != 0)
                                bracketCounter--;
                            else
                                return Finish(token);
                        }
                        ProcessSymbol(token);
                        start++;
                        break;
                    }
                    return Finish(token);
                default:
                    return Finish(token);
            }
        }
        CCompiler.RaiseUnexpectedEOFException(fileName, tokens);
        throw new NotImplementedException();
    }

    private void CheckOutputStack(Token t)
    {
        if (_outputPointer >= _output.Length)
            CCompiler.RaiseException("output stack overflow", t);
    }
    
    private void CheckOperationStack(Token t)
    {
        if (_opStackPointer >= _opStack.Length)
            CCompiler.RaiseException("operation stack overflow", t);
    }

    private void SyntaxError(Token t) => CCompiler.RaiseException("syntax error", t);
    
    private void StoreData(Token token, int? value, Variable? var)
    {
        _prevOp = false;
        CheckOutputStack(token);
        _output[_outputPointer++] = new OutputItem(null, value, var, token);
    }

    private void MoveToOutput(int priority, Token token)
    {
        while (_opStackPointer > 0)
        {
            var v = _opStack[_opStackPointer - 1];
            if (v == "(")
                return;
            var opPriority = Priorities[v];
            if (opPriority < priority)
                return;
            CheckOutputStack(token);
            _output[_outputPointer++] = new OutputItem(_opStack[--_opStackPointer], null, null, token);
        }
    }
    
    private void Operation(string opName, Token token)
    {
        MoveToOutput(Priorities[opName], token);
        CheckOperationStack(token);
        _opStack[_opStackPointer++] = opName;
    }
    
    private void ProcessSymbol(Token token)
    {
        if (token.StringValue == "(")
        {
            CheckOperationStack(token);
            _opStack[_opStackPointer++] = token.StringValue;
            _prevOp = true;
        }
        else if (token.StringValue == ")")
        {
            if (_prevOp)
                SyntaxError(token);
            MoveToOutput(0, token);
            if (_opStackPointer == 0)
                CCompiler.RaiseException("( is missing", token);
            _opStackPointer--;
        }
        else
        {
            if (_prevOp && token.StringValue != "~")
                SyntaxError(token);
            Operation(token.StringValue, token);
            _prevOp = true;
        }
    }

    private void ProcessNumber(Token token)
    {
        StoreData(token, token.IntValue, null);
    }

    private void ProcessName(Token t)
    {
        var variable = _programBlock.GetVariable(t.StringValue);
        if (variable == null)
            CCompiler.RaiseException($"Unknown variable {t.StringValue}", t);
        else
            StoreData(t, null, variable);
    }

    private List<OutputItem> Finish(Token token)
    {
        MoveToOutput(0, token);
        if (_opStackPointer > 0)
            CCompiler.RaiseException(") is missing", token);
        if (_outputPointer == 0)
            CCompiler.RaiseException("empty statement", token);
        var result = new List<OutputItem>();
        for (var i = 0; i < _outputPointer; i++)
        {
            var data = _output[i];
            switch (data.Op)
            {
                case null:
                    result.Add(data);
                    break;
                case "~":
                    Operation(data.T, result, v => ~v);
                    break;
                case "+":
                    Operation2(data.T, result, (v, v2) => v + v2);
                    break;
                case "-":
                    Operation2(data.T, result, (v, v2) => v - v2);
                    break;
                case "*":
                    Operation2(data.T, result, (v, v2) => v * v2);
                    break;
                case "/":
                    Operation2(data.T, result, (v, v2) => v / v2);
                    break;
                case "<<":
                    Operation2(data.T, result, (v, v2) => v << v2);
                    break;
                case ">>":
                    Operation2(data.T, result, (v, v2) => v >> v2);
                    break;
                case "&":
                    Operation2(data.T, result, (v, v2) => v & v2);
                    break;
                case "|":
                    Operation2(data.T, result, (v, v2) => v | v2);
                    break;
                case "^":
                    Operation2(data.T, result, (v, v2) => v ^ v2);
                    break;
                case "<":
                    Operation2(data.T, result, (v, v2) => v < v2 ? 1 : 0);
                    break;
                case ">":
                    Operation2(data.T, result, (v, v2) => v > v2 ? 1 : 0);
                    break;
                case "==":
                    Operation2(data.T, result, (v, v2) => v == v2 ? 1 : 0);
                    break;
                case "!=":
                    Operation2(data.T, result, (v, v2) => v != v2 ? 1 : 0);
                    break;
                case ">=":
                    Operation2(data.T, result, (v, v2) => v >= v2 ? 1 : 0);
                    break;
                case "<=":
                    Operation2(data.T, result, (v, v2) => v <= v2 ? 1 : 0);
                    break;
                case "&&":
                    Operation2(data.T, result, (v, v2) => (v != 0) && (v2 != 0) ? 1 : 0);
                    break;
                case "||":
                    Operation2(data.T, result, (v, v2) => (v != 0) || (v2 != 0) ? 1 : 0);
                    break;
                default:
                    SyntaxError(token);
                    break;
            }
        }
        return result;
    }

    private static void Operation(Token token, List<OutputItem> result, Func<int, int> operation)
    {
        if (result.Count == 0)
            CCompiler.RaiseException("result list is empty", token);
        var item = result[^1];
        if (item.Value != null)
            item.Value = operation((int)item.Value);
    }
    
    private static void Operation2(Token token, List<OutputItem> result, Func<int, int, int> operation)
    {
        if (result.Count < 2)
            CCompiler.RaiseException("result list length should be > 1", token);
        var item = result[^1];
        var item2 = result[^2];
        if (item.Value != null && item2.Value != null)
        {
            item2.Value = operation((int)item.Value, (int)item2.Value);
            result.RemoveAt(result.Count - 1);
        }
    }

    public static int Calculate(Token token, List<OutputItem> expression)
    {
        if (expression.Count != 1 || expression[0].Value == null)
            CCompiler.RaiseException("invalid expression", token);
        return (int)expression[0].Value!;
    }
}
