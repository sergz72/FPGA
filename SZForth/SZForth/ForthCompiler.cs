namespace SZForth;

internal sealed class ForthCompiler
{
    private enum ConditionType
    {
        If,
        Else,
        Begin,
        While
    }

    private record Condition(ConditionType Type, JmpInstruction? I, int Pc);
    
    private readonly List<Token> _tokens;
    private readonly Stack<int> _dataStack;
    private readonly int _bits;
    private readonly Dictionary<string, int> _constantsAndVariables;
    private readonly Dictionary<string, List<Instruction>> _words;
    private readonly Dictionary<string, int> _wordAddresses;
    private readonly ParsedConfiguration _config;
    private readonly Stack<Condition> _conditionStack;
    private List<Instruction> _currentWordInstructions, _dataInstructions, _roDataInstructions;
    private string _currentWord;
    private int _nextVariableAddress;
    private int _nextRoDataAddress;
    private bool _compileMode;
    private int _wordPc;
    
    internal ForthCompiler(ParsedConfiguration config, List<string> sources, int bits)
    {
        _config = config;
        _tokens = new ForthParser(sources.Select(source => new ParserFile(source))).Parse();
        _dataStack = new Stack<int>();
        _bits = bits;
        _constantsAndVariables = new Dictionary<string, int>();
        _words = new Dictionary<string, List<Instruction>>();
        _wordAddresses = new Dictionary<string, int>();
        _currentWordInstructions = [];
        _dataInstructions = [];
        _roDataInstructions = [];
        _conditionStack = new Stack<Condition>();
        _currentWord = "";
    }
    
    internal CompilerResult Compile()
    {
        _nextVariableAddress = (int)_config.Data.Address;
        _nextRoDataAddress = (int)_config.RoData.Address;
        _dataInstructions = [];
        _roDataInstructions = [];
        _wordAddresses.Clear();
        _dataStack.Clear();
        var start = 0;
        _compileMode = false;
        while (start < _tokens.Count)
        {
            if (_compileMode)
            {
                var token = _tokens[start++];
                var i = Compile(token);
                if (i != null)
                {
                    _wordPc += i.Size;
                    _currentWordInstructions.Add(i);
                }

                if (!_compileMode)
                {
                    if (_conditionStack.Count != 0)
                        throw new CompilerException($"{_currentWord}: Condition stack is not empty");
                    _words.Add(_currentWord, _currentWordInstructions);
                }
            }
            else
                Interpret(ref start);
        }
        var codeInstructions = BuildCodeInstructions();
        LinkInstructions(codeInstructions, _dataInstructions, _roDataInstructions);
        return new CompilerResult(codeInstructions, _dataInstructions, _roDataInstructions);
    }

    private void LinkInstructions(params List<Instruction>[] instructions)
    {
        foreach (var instructionList in instructions)
            LinkInstructionList(instructionList);
    }

    private void LinkInstructionList(List<Instruction> instructions)
    {
        int pc = 0;
        foreach (var instruction in instructions)
        {
            var address = instruction.RequiredLabel != null ? GetLabelAddress(instruction.RequiredLabel) : 0;
            instruction.BuildCode(address, pc);
            pc += instruction.Size;
        }
    }

    private List<Instruction> BuildCodeInstructions()
    {
        var result = new List<Instruction>();
        int pc = 0;

        if (_config.Code.IsrHandlers.Length != 0)
        {
            var ins = new LabelInstruction(InstructionCodes.Jmp, "jmp", _config.Code.EntryPoint, _bits);
            result.Add(ins);
            pc += ins.Size;
        }

        for (var i = 0; i < _config.Code.IsrHandlers.Length - 1; i++)
        {
            var ins = new LabelInstruction(InstructionCodes.Jmp, "jmp", _config.Code.IsrHandlers[i], _bits);
            result.Add(ins);
            pc += ins.Size;
        }

        if (_config.Code.IsrHandlers.Length != 0)
        {
            var word = _config.Code.IsrHandlers[^1];
            _wordAddresses.Add(word, pc);
            var ins = BuildCodeInstructions(pc, _words[word]);
            result.AddRange(ins);
            pc += ins.Count;
        }

        foreach (var word in _words.Keys.Where(NotLastIsrHandler))
        {
            _wordAddresses.Add(word, pc);
            var ins = BuildCodeInstructions(pc, _words[word]);
            result.AddRange(ins);
            pc += ins.Count;
        }

        return result;
    }

    private bool NotLastIsrHandler(string word)
    {
        if (_config.Code.IsrHandlers.Length != 0)
            return word != _config.Code.IsrHandlers[^1];
        return true;
    }

    private List<Instruction> BuildCodeInstructions(int pc, List<Instruction> wordInstructions)
    {
        return wordInstructions;
    }

    private void Interpret(ref int start)
    {
        var token = _tokens[start];
        switch (token.Type)
        {
            case TokenType.Number:
                _dataStack.Push((int)token.IntValue!);
                start++;
                break;
            default:
                if (_constantsAndVariables.TryGetValue(token.Word, out var value))
                {
                    _dataStack.Push(value);
                    start++;
                }
                else
                    InterpretWord(ref start);
                break;
        }
    }

    private void InterpretWord(ref int start)
    {
        var token = _tokens[start++];
        int v1, v2;
        switch (token.Word)
        {
            case "variable":
                InterpretVariableDefinition(false, ref start);
                break;
            case "ivariable":
                InterpretVariableDefinition(true, ref start);
                break;
            case "array":
                InterpretArrayDefinition(ref start);
                break;
            case "constant":
                InterpretConstantDefinition(ref start);
                break;
            case "+":
                v1 = _dataStack.Pop();
                v2 = _dataStack.Pop();
                _dataStack.Push(v1 + v2);
                break;
            case "-":
                v1 = _dataStack.Pop();
                v2 = _dataStack.Pop();
                _dataStack.Push(v1 - v2);
                break;
            case "*":
                v1 = _dataStack.Pop();
                v2 = _dataStack.Pop();
                _dataStack.Push(v1 * v2);
                break;
            case "/":
                v1 = _dataStack.Pop();
                v2 = _dataStack.Pop();
                _dataStack.Push(v1 / v2);
                break;
            case ":":
                InterpretWordDefinition(ref start);
                break;
            default:
                throw new CompilerException($"unexpected word {token.Word} at", token);
        }
    }

    private void InterpretWordDefinition(ref int start)
    {
        var name = GetName(start);
        if (_constantsAndVariables.ContainsKey(name.Word) || _words.ContainsKey(name.Word))
            throw new CompilerException($"constant/variable/array/word with name {name.Word} already exists", _tokens[start]);
        _compileMode = true;
        _currentWordInstructions = [];
        _currentWord = name.Word;
        _wordPc = 0;
        start++;
    }

    private Instruction? Compile(Token token)
    {
        switch (token.Type)
        {
            case TokenType.Number:
                return new PushDataInstruction("", (int)token.IntValue!, _bits);
            default:
                return CompileWord(token);
        }
    }
    
    private Instruction? CompileWord(Token token)
    {
        JmpInstruction i;
        Condition? c;
        switch (token.Word)
        {
            case ";":
                _compileMode = false;
                return _config.Code.IsrHandlers.Contains(_currentWord) ?
                    new OpcodeInstruction((uint)InstructionCodes.Reti, "reti") :
                    new OpcodeInstruction((uint)InstructionCodes.Ret, "ret");
            case "dup":
                return new OpcodeInstruction((uint)InstructionCodes.Dup, token.Word);
            case "drop":
                return new OpcodeInstruction((uint)InstructionCodes.Drop, token.Word);
            case "@":
                return new OpcodeInstruction((uint)InstructionCodes.Get, "get");
            case "!":
                return new OpcodeInstruction((uint)InstructionCodes.Set, "set");
            case "+":
                return new OpcodeInstruction((uint)InstructionCodes.AluOp + (uint)AluOperations.Add, token.Word);
            case "-":
                return new OpcodeInstruction((uint)InstructionCodes.AluOp + (uint)AluOperations.Sub, token.Word);
            case "*":
                return new OpcodeInstruction((uint)InstructionCodes.AluOp + (uint)AluOperations.Mul, token.Word);
            case "/":
                return new OpcodeInstruction((uint)InstructionCodes.AluOp + (uint)AluOperations.Div, token.Word);
            case "=":
                return new OpcodeInstruction((uint)InstructionCodes.AluOp + (uint)AluOperations.Eq, token.Word);
            case "!=":
                return new OpcodeInstruction((uint)InstructionCodes.AluOp + (uint)AluOperations.Ne, token.Word);
            case "<":
                return new OpcodeInstruction((uint)InstructionCodes.AluOp + (uint)AluOperations.Lt, token.Word);
            case "<=":
                return new OpcodeInstruction((uint)InstructionCodes.AluOp + (uint)AluOperations.Le, token.Word);
            case ">":
                return new OpcodeInstruction((uint)InstructionCodes.AluOp + (uint)AluOperations.Gt, token.Word);
            case ">=":
                return new OpcodeInstruction((uint)InstructionCodes.AluOp + (uint)AluOperations.Ge, token.Word);
            case "and":
                return new OpcodeInstruction((uint)InstructionCodes.AluOp + (uint)AluOperations.And, token.Word);
            case "or":
                return new OpcodeInstruction((uint)InstructionCodes.AluOp + (uint)AluOperations.Or, token.Word);
            case "xor":
                return new OpcodeInstruction((uint)InstructionCodes.AluOp + (uint)AluOperations.Xor, token.Word);
            case "wfi":
                return new OpcodeInstruction((uint)InstructionCodes.Wfi, token.Word);
            case "hlt":
                return new OpcodeInstruction((uint)InstructionCodes.Hlt, token.Word);
            case "if0":
                i = new JmpInstruction(InstructionCodes.Br, "br", _bits, token.Word);
                _conditionStack.Push(new Condition(ConditionType.If, i, _wordPc));
                return i;
            case "if":
                i = new JmpInstruction(InstructionCodes.Br0, "br0", _bits, token.Word);
                _conditionStack.Push(new Condition(ConditionType.If, i, _wordPc));
                return i;
            case "then":
                if (!_conditionStack.TryPop(out c) || (c.Type != ConditionType.If && c.Type != ConditionType.Else))
                    throw new CompilerException("unexpected then", token);
                c.I!.Offset = _wordPc - c.Pc;
                break;
            case "else":
                if (!_conditionStack.TryPop(out c) || c.Type != ConditionType.If)
                    throw new CompilerException("unexpected else", token);
                i = new JmpInstruction(InstructionCodes.Jmp, "jmp", _bits, token.Word);
                c.I!.Offset = _wordPc + i.Size - c.Pc;
                _conditionStack.Push(new Condition(ConditionType.Else, i, _wordPc));
                return i;
            case "begin":
                _conditionStack.Push(new Condition(ConditionType.Begin, null, _wordPc));
                break;
            case "while":
                if (!_conditionStack.TryPeek(out c) || c.Type != ConditionType.Begin)
                    throw new CompilerException("unexpected while", token);
                i = new JmpInstruction(InstructionCodes.Br0, "br0", _bits, token.Word);
                _conditionStack.Push(new Condition(ConditionType.While, i, _wordPc));
                return i;
            case "while0":
                i = new JmpInstruction(InstructionCodes.Br, "br", _bits, token.Word);
                _conditionStack.Push(new Condition(ConditionType.While, i, _wordPc));
                return i;
            case "again":
                if (!_conditionStack.TryPop(out c) || c.Type != ConditionType.Begin)
                    throw new CompilerException("unexpected again", token);
                i = new JmpInstruction(InstructionCodes.Jmp, "jmp", _bits, token.Word);
                i.Offset = c.Pc - _wordPc;
                return i;
            case "repeat":
                if (!_conditionStack.TryPop(out var w) || w.Type != ConditionType.While)
                    throw new CompilerException("unexpected repeat", token);
                if (!_conditionStack.TryPop(out c) || c.Type != ConditionType.Begin)
                    throw new CompilerException("while without begin", token);
                i = new JmpInstruction(InstructionCodes.Jmp, "jmp", _bits, token.Word);
                i.Offset = c.Pc - _wordPc;
                w.I!.Offset = _wordPc + i.Size - w.Pc;
                return i;
            case "until":
                if (!_conditionStack.TryPop(out c) || c.Type != ConditionType.Begin)
                    throw new CompilerException("unexpected until", token);
                i = new JmpInstruction(InstructionCodes.Br, "br", _bits, token.Word);
                i.Offset = c.Pc - _wordPc;
                return i;
            case "until0":
                if (!_conditionStack.TryPop(out c) || c.Type != ConditionType.Begin)
                    throw new CompilerException("unexpected until0", token);
                i = new JmpInstruction(InstructionCodes.Br0, "br0", _bits, token.Word);
                i.Offset = c.Pc - _wordPc;
                return i;
            default:
                if (_constantsAndVariables.TryGetValue(token.Word, out var value))
                    return new PushDataInstruction(token.Word, value, _bits);
                return CompileCall(token.Word);
        }
        return null;
    }

    private Instruction CompileCall(string word)
    {
        return new LabelInstruction(InstructionCodes.Call, "call", word, _bits);
    }

    private void CheckWordExists(string name)
    {
        if (_words.ContainsKey(name))
            throw new CompilerException($"word with name {name} already exists");
    }
    private void InterpretVariableDefinition(bool init, ref int start)
    {
        var t = GetName(start);
        CheckWordExists(t.Word);
        if (!_constantsAndVariables.TryAdd(t.Word, (int)_nextVariableAddress++))
            throw new CompilerException("constant or variable {name} already defined", t);
        if (init)
            _dataInstructions.Add(new DataInstruction(t.Word, _dataStack.Pop()));
        start++;
    }

    private void InterpretArrayDefinition(ref int start)
    {
        var t = GetName(start);
        CheckWordExists(t.Word);
        if (!_constantsAndVariables.TryAdd(t.Word, (int)_nextVariableAddress))
            throw new CompilerException("constant or variable {name} already defined", t);
        start++;
        var v = GetNumber(start++);
        _nextVariableAddress += v;
    }
    
    private void InterpretConstantDefinition(ref int start)
    {
        var t = GetName(start);
        CheckWordExists(t.Word);
        if (!_constantsAndVariables.TryAdd(t.Word, _dataStack.Pop()))
            throw new CompilerException("constant or variable {name} already defined", t);
        start++;
    }
    
    private Token GetName(int start)
    {
        CheckEof(start);
        var token = _tokens[start];
        if (token.Type != TokenType.Word)
            throw new CompilerException("name expected", token);
        return token;
    }

    private int GetNumber(int start)
    {
        CheckEof(start);
        var token = _tokens[start];
        if (token.Type == TokenType.Number)
            return (int)token.IntValue!;
        if (!_constantsAndVariables.TryGetValue(token.Word, out var value))
            throw new CompilerException("number expected", token);
        return value;
    }
    
    private void CheckEof(int start)
    {
        if (start == _tokens.Count)
            throw new CompilerException("unexpected end of file");
    }

    private int GetLabelAddress(string? requiredLabel)
    {
        if (requiredLabel == null)
            return 0;
        if (_constantsAndVariables.TryGetValue(requiredLabel, out var address))
            return address;
        if (_wordAddresses.TryGetValue(requiredLabel, out var wordAddress))
            return wordAddress;
        throw new CompilerException($"{requiredLabel} not found");
    }
}

internal record CompilerResult(List<Instruction> CodeInstructions, List<Instruction> DataInstructions,
                                List<Instruction> RoDataInstructions);
internal class CompilerException: Exception
{
    internal CompilerException(string message, Token token): base($"{message}: {token.FileName}:{token.Line}:{token.Position}")
    {}
    
    internal CompilerException(string message): base(message)
    {}
}
