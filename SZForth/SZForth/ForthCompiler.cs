namespace SZForth;

internal sealed class ForthCompiler
{
    private enum ConditionType
    {
        If,
        Else,
        Begin,
        While,
        Case,
        Of,
        Do
    }

    private record Condition(ConditionType Type, List<JmpInstruction> I, int Pc, string Label = "");
    
    private readonly List<Token> _tokens;
    private readonly Stack<int> _dataStack;
    private readonly int _bits;
    private readonly Dictionary<string, int> _constantsAndVariables;
    private readonly Dictionary<string, List<Instruction>> _words;
    private readonly Dictionary<string, int> _wordAddresses;
    private readonly ParsedConfiguration _config;
    private readonly Stack<Condition> _conditionStack;
    private readonly List<JmpInstruction> _exitInstructions;
    private List<Instruction> _currentWordInstructions, _dataInstructions, _roDataInstructions;
    private string _currentWord;
    private int _nextVariableAddress;
    private int _nextRoDataAddress;
    private bool _compileMode;
    private int _wordPc;
    private int _currentLabelNumber;
    private string _nextLabel;
    private string[] _locals;
    
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
        _nextLabel = "";
        _locals = [];
        _exitInstructions = [];
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
                var i = Compile(token, ref start);
                if (i != null)
                {
                    _wordPc += i.Size;
                    _currentWordInstructions.Add(i);
                }

                if (!_compileMode)
                {
                    if (_conditionStack.Count != 0)
                        throw new CompilerException($"{_currentWord}: Condition stack is not empty");
                    _currentWordInstructions[0].Labels.Add(_currentWord);
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
            Instruction ins = new LabelInstruction(InstructionCodes.Jmp, "jmp", _config.Code.EntryPoint, _bits);
            result.Add(ins);
            pc += ins.Size;
            ins = new OpcodeInstruction((uint)InstructionCodes.Hlt, "hlt");
            result.Add(ins);
            pc += ins.Size;
        }

        for (var i = 0; i < _config.Code.IsrHandlers.Length - 1; i++)
        {
            Instruction ins = new LabelInstruction(InstructionCodes.Jmp, "jmp", _config.Code.IsrHandlers[i], _bits);
            result.Add(ins);
            pc += ins.Size;
            ins = new OpcodeInstruction((uint)InstructionCodes.Hlt, "hlt");
            result.Add(ins);
            pc += ins.Size;
        }

        if (_config.Code.IsrHandlers.Length != 0)
        {
            var word = _config.Code.IsrHandlers[^1];
            _wordAddresses.Add(word, pc);
            var ins = _words[word];
            result.AddRange(ins);
            pc += ins.Select(i => i.Size).Sum();
        }

        foreach (var word in _words.Keys.Where(NotLastIsrHandler))
        {
            _wordAddresses.Add(word, pc);
            var ins = _words[word];
            result.AddRange(ins);
            pc += ins.Select(i => i.Size).Sum();
        }

        return result;
    }

    private bool NotLastIsrHandler(string word)
    {
        if (_config.Code.IsrHandlers.Length != 0)
            return word != _config.Code.IsrHandlers[^1];
        return true;
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
                InterpretArrayDefinition(false, ref start);
                break;
            case "iarray":
                InterpretArrayDefinition(true, ref start);
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
        _currentLabelNumber = 0;
        _nextLabel = "";
        _locals = [];
        _exitInstructions.Clear();
        start++;
    }

    private Instruction? Compile(Token token, ref int start)
    {
        switch (token.Type)
        {
            case TokenType.Number:
                var i = new PushDataInstruction("", (int)token.IntValue!, _bits);
                if (_nextLabel != "")
                {
                    i.Labels.Add(_nextLabel);
                    _nextLabel = "";
                }
                return i;
            default:
                return CompileWord(token, ref start);
        }
    }

    private string BuildLabelName()
    {
        _currentLabelNumber++;
        return $"{_currentWord}_l{_currentLabelNumber}";
    }

    private Instruction BuildRetInstruction()
    {
        return _locals.Length == 0
            ? new OpcodeInstruction((uint)InstructionCodes.Ret, "ret")
            : new Opcode2Instruction((uint)InstructionCodes.Retn, (uint)_locals.Length, $"retn {_locals.Length}");
    }
    
    private Instruction? CompileWord(Token token, ref int start)
    {
        JmpInstruction j;
        Instruction? i = null;
        Condition? c;
        switch (token.Word)
        {
            case ";":
                _compileMode = false;
                foreach (var ei in _exitInstructions)
                    ei.Offset = _wordPc - ei.Offset;
                i = _config.Code.IsrHandlers.Contains(_currentWord) ?
                    new OpcodeInstruction((uint)InstructionCodes.Reti, "reti") : BuildRetInstruction();
                break;
            case "dup":
                i = new OpcodeInstruction((uint)InstructionCodes.Dup, token.Word);
                break;
            case "drop":
                i = new OpcodeInstruction((uint)InstructionCodes.Drop, token.Word);
                break;
            case "swap":
                i = new OpcodeInstruction((uint)InstructionCodes.Swap, token.Word);
                break;
            case "rot":
                i = new OpcodeInstruction((uint)InstructionCodes.Rot, token.Word);
                break;
            case "over":
                i = new OpcodeInstruction((uint)InstructionCodes.Over, token.Word);
                break;
            case "@":
                i = new OpcodeInstruction((uint)InstructionCodes.Get, "get");
                break;
            case "!":
                i = new OpcodeInstruction((uint)InstructionCodes.Set, "set");
                break;
            case "+":
                i = new OpcodeInstruction((uint)InstructionCodes.AluOp + (uint)AluOperations.Add, token.Word);
                break;
            case "-":
                i = new OpcodeInstruction((uint)InstructionCodes.AluOp + (uint)AluOperations.Sub, token.Word);
                break;
            case "*":
                i = new OpcodeInstruction((uint)InstructionCodes.AluOp + (uint)AluOperations.Mul, token.Word);
                break;
            case "/":
                i = new OpcodeInstruction((uint)InstructionCodes.AluOp + (uint)AluOperations.Div, token.Word);
                break;
            case "=":
                i = new OpcodeInstruction((uint)InstructionCodes.AluOp + (uint)AluOperations.Eq, token.Word);
                break;
            case "!=":
                i = new OpcodeInstruction((uint)InstructionCodes.AluOp + (uint)AluOperations.Ne, token.Word);
                break;
            case "<":
                i = new OpcodeInstruction((uint)InstructionCodes.AluOp + (uint)AluOperations.Lt, token.Word);
                break;
            case "<=":
                i = new OpcodeInstruction((uint)InstructionCodes.AluOp + (uint)AluOperations.Le, token.Word);
                break;
            case ">":
                i = new OpcodeInstruction((uint)InstructionCodes.AluOp + (uint)AluOperations.Gt, token.Word);
                break;
            case ">=":
                i = new OpcodeInstruction((uint)InstructionCodes.AluOp + (uint)AluOperations.Ge, token.Word);
                break;
            case "and":
                i = new OpcodeInstruction((uint)InstructionCodes.AluOp + (uint)AluOperations.And, token.Word);
                break;
            case "or":
                i = new OpcodeInstruction((uint)InstructionCodes.AluOp + (uint)AluOperations.Or, token.Word);
                break;
            case "xor":
                i = new OpcodeInstruction((uint)InstructionCodes.AluOp + (uint)AluOperations.Xor, token.Word);
                break;
            case "lshift":
                i = new OpcodeInstruction((uint)InstructionCodes.AluOp + (uint)AluOperations.Shl, token.Word);
                break;
            case "rshift":
                i = new OpcodeInstruction((uint)InstructionCodes.AluOp + (uint)AluOperations.Shr, token.Word);
                break;
            case "mod":
                i = new OpcodeInstruction((uint)InstructionCodes.AluOp + (uint)AluOperations.Rem, token.Word);
                break;
            case "wfi":
                i = new OpcodeInstruction((uint)InstructionCodes.Wfi, token.Word);
                break;
            case "hlt":
                i = new OpcodeInstruction((uint)InstructionCodes.Hlt, token.Word);
                break;
            case "if0":
                j = new JmpInstruction(InstructionCodes.Br, "br", _bits, BuildLabelName());
                _conditionStack.Push(new Condition(ConditionType.If, [j], _wordPc));
                i = j;
                break;
            case "if":
                j = new JmpInstruction(InstructionCodes.Br0, "br0", _bits, BuildLabelName());
                _conditionStack.Push(new Condition(ConditionType.If, [j], _wordPc));
                i = j;
                break;
            case "then":
                if (!_conditionStack.TryPop(out c) || (c.Type != ConditionType.If && c.Type != ConditionType.Else))
                    throw new CompilerException("unexpected then", token);
                c.I[0].Offset = _wordPc - c.Pc;
                _nextLabel = c.I[0].JmpTo;
                break;
            case "else":
                if (!_conditionStack.TryPop(out c) || c.Type != ConditionType.If)
                    throw new CompilerException("unexpected else", token);
                j = new JmpInstruction(InstructionCodes.Jmp, "jmp", _bits, BuildLabelName());
                if (_nextLabel != "")
                    j.Labels.Add(_nextLabel);
                c.I[0].Offset = _wordPc + j.Size - c.Pc;
                _conditionStack.Push(new Condition(ConditionType.Else, [j], _wordPc));
                _nextLabel = c.I[0].JmpTo;
                return j;
            case "begin":
                _nextLabel = BuildLabelName();
                _conditionStack.Push(new Condition(ConditionType.Begin, [], _wordPc, _nextLabel));
                break;
            case "case":
                _conditionStack.Push(new Condition(ConditionType.Case, [], _wordPc, BuildLabelName()));
                i = new OpcodeInstruction((uint)InstructionCodes.Dup, token.Word);
                break;
            case "of":
                if (!_conditionStack.TryPeek(out c) || c.Type != ConditionType.Case)
                    throw new CompilerException("unexpected of", token);
                j = new OfInstruction(_bits, BuildLabelName());
                _conditionStack.Push(new Condition(ConditionType.Of, [j], _wordPc));
                i = j;
                break;
            case "endof":
                if (!_conditionStack.TryPop(out c) || c.Type != ConditionType.Of)
                    throw new CompilerException("unexpected endof", token);
                if (!_conditionStack.TryPeek(out var cs) || cs.Type != ConditionType.Case)
                    throw new CompilerException("endof without case", token);
                j = new JmpDupInstruction(_bits, cs.Label);
                j.Offset = _wordPc;
                if (_nextLabel != "")
                    j.Labels.Add(_nextLabel);
                cs.I.Add(j);
                c.I[0].Offset = _wordPc + j.Size - 1 - c.Pc;
                _nextLabel = c.I[0].JmpTo;
                return j;
            case "endcase":
                if (!_conditionStack.TryPop(out c) || c.Type != ConditionType.Case)
                    throw new CompilerException("unexpected endcase", token);
                UpdateJumps(c, 0);
                _nextLabel = c.Label;
                break;
            case "while":
                if (!_conditionStack.TryPeek(out c) || c.Type != ConditionType.Begin)
                    throw new CompilerException("unexpected while", token);
                j = new JmpInstruction(InstructionCodes.Br0, "br0", _bits, BuildLabelName());
                _conditionStack.Push(new Condition(ConditionType.While, [j], _wordPc));
                i = j;
                break;
            case "while0":
                if (!_conditionStack.TryPeek(out c) || c.Type != ConditionType.Begin)
                    throw new CompilerException("unexpected while0", token);
                j = new JmpInstruction(InstructionCodes.Br, "br", _bits, BuildLabelName());
                _conditionStack.Push(new Condition(ConditionType.While, [j], _wordPc));
                i = j;
                break;
            case "again":
                if (!_conditionStack.TryPop(out c) || c.Type != ConditionType.Begin)
                    throw new CompilerException("unexpected again", token);
                j = new JmpInstruction(InstructionCodes.Jmp, "jmp", _bits, c.Label);
                j.Offset = c.Pc - _wordPc;
                i = j;
                UpdateJumps(c, j.Size);
                break;
            case "repeat":
                if (!_conditionStack.TryPop(out var w) || w.Type != ConditionType.While)
                    throw new CompilerException("unexpected repeat", token);
                if (!_conditionStack.TryPop(out c) || c.Type != ConditionType.Begin)
                    throw new CompilerException("while without begin", token);
                j = new JmpInstruction(InstructionCodes.Jmp, "jmp", _bits, c.Label);
                if (_nextLabel != "")
                    j.Labels.Add(_nextLabel);
                j.Offset = c.Pc - _wordPc;
                w.I[0].Offset = _wordPc + j.Size - w.Pc;
                _nextLabel = w.I[0].JmpTo;
                UpdateJumps(c, j.Size);
                return j;
            case "until":
                if (!_conditionStack.TryPop(out c) || c.Type != ConditionType.Begin)
                    throw new CompilerException("unexpected until", token);
                j = new JmpInstruction(InstructionCodes.Br, "br", _bits, c.Label);
                j.Offset = c.Pc - _wordPc;
                i = j;
                UpdateJumps(c, j.Size);
                break;
            case "until0":
                if (!_conditionStack.TryPop(out c) || c.Type != ConditionType.Begin)
                    throw new CompilerException("unexpected until0", token);
                j = new JmpInstruction(InstructionCodes.Br0, "br0", _bits, c.Label);
                j.Offset = c.Pc - _wordPc;
                i = j;
                UpdateJumps(c, j.Size);
                break;
            case "do":
                var d = new OpcodeInstruction((uint)InstructionCodes.PstackPush, "do");
                if (_nextLabel != "")
                    d.Labels.Add(_nextLabel);
                _nextLabel = BuildLabelName();
                _conditionStack.Push(new Condition(ConditionType.Do, [], _wordPc, _nextLabel));
                return d;
            case "loop":
                if (!_conditionStack.TryPop(out c) || c.Type != ConditionType.Do)
                    throw new CompilerException("unexpected loop", token);
                j = new LoopInstruction(_bits, c.Label);
                j.Offset = c.Pc - _wordPc;
                i = j;
                UpdateJumps(c, j.Size);
                break;
            case "+loop":
                if (!_conditionStack.TryPop(out c) || c.Type != ConditionType.Do)
                    throw new CompilerException("unexpected +loop", token);
                j = new PLoopInstruction(_bits, c.Label);
                j.Offset = c.Pc - _wordPc;
                i = j;
                UpdateJumps(c, j.Size);
                break;
            case "leave":
                c = _conditionStack
                    .LastOrDefault(cn => cn!.Type == ConditionType.Do || cn.Type == ConditionType.Begin, null);
                if (c == null)
                    throw new CompilerException("unexpected leave", token);
                j = new JmpInstruction(InstructionCodes.Jmp, "jmp", _bits, "leave");
                j.Offset = _wordPc;
                c.I.Add(j);
                i = j;
                break;
            case "exit":
                j = new JmpInstruction(InstructionCodes.Jmp, "jmp", _bits, "exit");
                j.Offset = _wordPc;
                _exitInstructions.Add(j);
                i = j;
                //todo
                break;
            case "locals":
                var t = GetName(start);
                start++;
                _locals = t.Word.Split(',');
                i = new Opcode2Instruction((uint)InstructionCodes.Locals, (uint)_locals.Length, $"locals {_locals.Length}");
                break;
            default:
                i = CompileLocalVariableOperation(token.Word);
                if (i == null)
                {
                    if (_constantsAndVariables.TryGetValue(token.Word, out var value))
                        i = new PushDataInstruction(token.Word, value, _bits);
                    else
                        i = CompileCall(token.Word);
                }
                break;
        }

        if (i != null && _nextLabel != "")
        {
            i.Labels.Add(_nextLabel);
            _nextLabel = "";
        }

        return i;
    }

    private void UpdateJumps(Condition c, int jSize)
    {
        foreach (var j in c.I)
            j.Offset = _wordPc + jSize - j.Offset;
    }

    private Instruction? CompileLocalVariableOperation(string word)
    {
        if (_locals.Length == 0)
            return null;
        var set = word is [.., _, '!']; 
        var get = word is [.., _, '@'];
        if (!set & !get)
            return null;
        var idx = _locals
            .Select((l, i) => (l, i))
            .Where(l => l.l == word[..^1])
            .Select(l => l.i)
            .FirstOrDefault(-1);
        if (idx < 0)
            return null;
        return set ? new Opcode2Instruction((uint)InstructionCodes.LocalSet, (uint)idx, $"set {_locals[idx]}") :
                     new Opcode2Instruction((uint)InstructionCodes.LocalGet, (uint)idx, $"get {_locals[idx]}");
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
        if (!_constantsAndVariables.TryAdd(t.Word, _nextVariableAddress++))
            throw new CompilerException("constant or variable {name} already defined", t);
        if (init)
            _dataInstructions.Add(new DataInstruction(t.Word, _dataStack.Pop()));
        start++;
    }

    private void InterpretArrayDefinition(bool init, ref int start)
    {
        var t = GetName(start);
        CheckWordExists(t.Word);
        if (!_constantsAndVariables.TryAdd(t.Word, _nextVariableAddress))
            throw new CompilerException("constant or variable {name} already defined", t);
        start++;
        var v = GetNumber(start++);
        if (init)
        {
            for (var i = 0; i < v; i++)
                _dataInstructions.Add(new DataInstruction(t.Word, _dataStack.Pop()));
        }
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
