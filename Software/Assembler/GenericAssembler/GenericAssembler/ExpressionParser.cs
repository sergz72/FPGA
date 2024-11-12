namespace GenericAssembler;


public sealed class ExpressionParser
{
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
        { "U-", 3 },
        
        { "&", 2 },
        { "^", 2 },
        { "|", 2 },
        
        { "||", 1 },
        { "&&", 1 }
    };

    private static readonly HashSet<string> AllowedSymbols;

    static ExpressionParser()
    {
        AllowedSymbols = Priorities.Select(p => p.Key).ToHashSet();
        AllowedSymbols.Add("(");
        AllowedSymbols.Add(")");
    }
    
    private record OutputItem(string? Op, long Value);

    private readonly OutputItem[] _output;
    private readonly string[] _opStack;
    private readonly long[] _dataStack;
    private readonly ICompiler _compiler;
    private readonly int _stackSize;
    private int _outputPointer;
    private int _opStackPointer;
    private bool _prevOp;
    
    public ExpressionParser(int stackSize, ICompiler compiler)
    {
        _output = new OutputItem[stackSize];
        _opStack = new string[stackSize];
        _dataStack = new long[stackSize];
        _stackSize = stackSize;
        _compiler = compiler;
    }

    private void CheckOperationStack()
    {
        if (_opStackPointer >= _stackSize)
            _compiler.RaiseException("operation stack overflow");
    }

    private void CheckOutputStack()
    {
        if (_outputPointer >= _stackSize)
            _compiler.RaiseException("output stack overflow");
    }
    
    private void SyntaxError() => _compiler.RaiseException("syntax error");
    
    public long Parse(List<Token> tokens, ref int start)
    {
        _outputPointer = _opStackPointer = 0;
        _prevOp = true;
        while (start < tokens.Count)
        {
            var token = tokens[start];
            var finish = false;
            switch (token.Type)
            {
                case TokenType.Number:
                    StoreNumber(token.LongValue);
                    break;
                case TokenType.Name:
                    StoreNumber(_compiler.FindConstantValue(token.StringValue));
                    break;
                case TokenType.Symbol:
                    if (!AllowedSymbols.Contains(token.StringValue))
                    {
                        finish = true;
                        break;
                    }
                    if (token.StringValue == "(")
                    {
                        CheckOperationStack();
                        _opStack[_opStackPointer++] = token.StringValue;
                        _prevOp = true;
                    }
                    else if (token.StringValue == ")")
                    {
                        if (_prevOp)
                            SyntaxError();
                        MoveToOutput(0);
                        if (_opStackPointer == 0)
                            _compiler.RaiseException("( is missing");
                        _opStackPointer--;
                    }
                    else
                    {
                        if (_prevOp && token.StringValue != "~" && token.StringValue != "-")
                            SyntaxError();
                        Operation(token.StringValue == "-" ? "U-" : token.StringValue);
                        _prevOp = true;
                    }
                    break;
                default:
                    SyntaxError();
                    break;
            }
            if (finish)
                break;
            start++;
        }
        return Finish();
    }

    private long Finish()
    {
        MoveToOutput(0);
        if (_opStackPointer > 0)
            _compiler.RaiseException(") is missing");
        if (_outputPointer == 0)
            _compiler.RaiseException("empty statement");
        for (var i = 0; i < _outputPointer; i++)
        {
            var data = _output[i];
            switch (data.Op)
            {
                case null:
                    if (_opStackPointer >= _stackSize)
                        _compiler.RaiseException("data stack overflow");
                    _dataStack[_opStackPointer++] = data.Value;
                    break;
                case "~":
                    _dataStack[_opStackPointer - 1] = ~_dataStack[_opStackPointer - 1];
                    break;
                case "U-":
                    _dataStack[_opStackPointer - 1] = -_dataStack[_opStackPointer - 1];
                    break;
                case "+":
                    _opStackPointer--;
                    _dataStack[_opStackPointer - 1] += GetOperand();
                    break;
                case "-":
                    _opStackPointer--;
                    _dataStack[_opStackPointer - 1] -= GetOperand();
                    break;
                case "*":
                    _opStackPointer--;
                    _dataStack[_opStackPointer - 1] *= GetOperand();
                    break;
                case "/":
                    _opStackPointer--;
                    _dataStack[_opStackPointer - 1] /= GetOperand();
                    break;
                case "<<":
                    _opStackPointer--;
                    _dataStack[_opStackPointer - 1] <<= (int)GetOperand();
                    break;
                case ">>":
                    _opStackPointer--;
                    _dataStack[_opStackPointer - 1] >>= (int)GetOperand();
                    break;
                case "&":
                    _opStackPointer--;
                    _dataStack[_opStackPointer - 1] &= GetOperand();
                    break;
                case "|":
                    _opStackPointer--;
                    _dataStack[_opStackPointer - 1] |= GetOperand();
                    break;
                case "^":
                    _opStackPointer--;
                    _dataStack[_opStackPointer - 1] ^= GetOperand();
                    break;
                case "<":
                    _opStackPointer--;
                    _dataStack[_opStackPointer - 1] = _dataStack[_opStackPointer - 1] < GetOperand() ? 1 : 0;
                    break;
                case ">":
                    _opStackPointer--;
                    _dataStack[_opStackPointer - 1] = _dataStack[_opStackPointer - 1] > GetOperand() ? 1 : 0;
                    break;
                case "==":
                    _opStackPointer--;
                    _dataStack[_opStackPointer - 1] = _dataStack[_opStackPointer - 1] == GetOperand() ? 1 : 0;
                    break;
                case "!=":
                    _opStackPointer--;
                    _dataStack[_opStackPointer - 1] = _dataStack[_opStackPointer - 1] != GetOperand() ? 1 : 0;
                    break;
                case ">=":
                    _opStackPointer--;
                    _dataStack[_opStackPointer - 1] = _dataStack[_opStackPointer - 1] >= GetOperand() ? 1 : 0;
                    break;
                case "<=":
                    _opStackPointer--;
                    _dataStack[_opStackPointer - 1] = _dataStack[_opStackPointer - 1] <= GetOperand() ? 1 : 0;
                    break;
                case "&&":
                    _opStackPointer--;
                    _dataStack[_opStackPointer - 1] = _dataStack[_opStackPointer - 1] != 0 && GetOperand() != 0 ? 1 : 0;
                    break;
                case "||":
                    _opStackPointer--;
                    _dataStack[_opStackPointer - 1] = _dataStack[_opStackPointer - 1] != 0 || GetOperand() != 0 ? 1 : 0;
                    break;
                default:
                    SyntaxError();
                    break;
            }
        }

        if (_opStackPointer != 1)
            SyntaxError();
            
        return _dataStack[0];
    }

    private long GetOperand()
    {
        if (_opStackPointer < 1)
            SyntaxError();
        return _dataStack[_opStackPointer];
    }
    
    private void MoveToOutput(int priority)
    {
        while (_opStackPointer > 0)
        {
            var v = _opStack[_opStackPointer - 1];
            if (v == "(")
                return;
            var opPriority = Priorities[v];
            if (opPriority < priority)
                return;
            CheckOutputStack();
            _output[_outputPointer++] = new OutputItem(_opStack[--_opStackPointer], 0);
        }
    }
    
    private void Operation(string opName)
    {
        MoveToOutput(Priorities[opName]);
        CheckOperationStack();
        _opStack[_opStackPointer++] = opName;
    }

    private void StoreNumber(long value)
    {
        _prevOp = false;
        CheckOutputStack();
        _output[_outputPointer++] = new OutputItem(null, value);
    }
}