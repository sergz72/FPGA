namespace SZForth;

internal sealed class CodeGenerator
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

    private readonly ForthCompiler _compiler;
    private readonly Stack<Condition> _conditionStack;
    private readonly List<JmpInstruction> _exitInstructions;
    private int _currentLabelNumber;
    private string _nextLabel;
    private string[] _locals;
    internal string CurrentWord { get; private set; }
    internal int WordPc { get; set; }

    internal CodeGenerator(ForthCompiler compiler)
    {
        _compiler = compiler;
        _conditionStack = new Stack<Condition>();
        CurrentWord = "";
        _nextLabel = "";
        _locals = [];
        _exitInstructions = [];
    }

    internal void Init(string currentWord)
    {
        CurrentWord = currentWord;
        WordPc = 0;
        _currentLabelNumber = 0;
        _nextLabel = "";
        _locals = [];
        _exitInstructions.Clear();
    }

    internal void Finish()
    {
        if (_conditionStack.Count != 0)
            throw new CompilerException($"{CurrentWord}: Condition stack is not empty");
    }
    
    private Instruction? CompileWord(Token token, ref int start)
    {
        JmpInstruction j;
        Instruction? i = null;
        Condition? c;
        switch (token.Word)
        {
            case ";":
                _compiler.CompileMode = false;
                foreach (var ei in _exitInstructions)
                    ei.Offset = WordPc - ei.Offset;
                i = _compiler.Config.Code.IsrHandlers.Contains(CurrentWord) ?
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
                j = new JmpInstruction(InstructionCodes.Br, "br", _compiler.Bits, BuildLabelName());
                _conditionStack.Push(new Condition(ConditionType.If, [j], WordPc));
                i = j;
                break;
            case "if":
                j = new JmpInstruction(InstructionCodes.Br0, "br0", _compiler.Bits, BuildLabelName());
                _conditionStack.Push(new Condition(ConditionType.If, [j], WordPc));
                i = j;
                break;
            case "then":
                if (!_conditionStack.TryPop(out c) || (c.Type != ConditionType.If && c.Type != ConditionType.Else))
                    throw new CompilerException("unexpected then", token);
                c.I[0].Offset = WordPc - c.Pc;
                _nextLabel = c.I[0].JmpTo;
                break;
            case "else":
                if (!_conditionStack.TryPop(out c) || c.Type != ConditionType.If)
                    throw new CompilerException("unexpected else", token);
                j = new JmpInstruction(InstructionCodes.Jmp, "jmp", _compiler.Bits, BuildLabelName());
                if (_nextLabel != "")
                    j.Labels.Add(_nextLabel);
                c.I[0].Offset = WordPc + j.Size - c.Pc;
                _conditionStack.Push(new Condition(ConditionType.Else, [j], WordPc));
                _nextLabel = c.I[0].JmpTo;
                return j;
            case "begin":
                _nextLabel = BuildLabelName();
                _conditionStack.Push(new Condition(ConditionType.Begin, [], WordPc, _nextLabel));
                break;
            case "case":
                _conditionStack.Push(new Condition(ConditionType.Case, [], WordPc, BuildLabelName()));
                i = new OpcodeInstruction((uint)InstructionCodes.Dup, token.Word);
                break;
            case "of":
                if (!_conditionStack.TryPeek(out c) || c.Type != ConditionType.Case)
                    throw new CompilerException("unexpected of", token);
                j = new OfInstruction(_compiler.Bits, BuildLabelName());
                _conditionStack.Push(new Condition(ConditionType.Of, [j], WordPc));
                i = j;
                break;
            case "endof":
                if (!_conditionStack.TryPop(out c) || c.Type != ConditionType.Of)
                    throw new CompilerException("unexpected endof", token);
                if (!_conditionStack.TryPeek(out var cs) || cs.Type != ConditionType.Case)
                    throw new CompilerException("endof without case", token);
                j = new JmpDupInstruction(_compiler.Bits, cs.Label);
                j.Offset = WordPc;
                if (_nextLabel != "")
                    j.Labels.Add(_nextLabel);
                cs.I.Add(j);
                c.I[0].Offset = WordPc + j.Size - 1 - c.Pc;
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
                j = new JmpInstruction(InstructionCodes.Br0, "br0", _compiler.Bits, BuildLabelName());
                _conditionStack.Push(new Condition(ConditionType.While, [j], WordPc));
                i = j;
                break;
            case "while0":
                if (!_conditionStack.TryPeek(out c) || c.Type != ConditionType.Begin)
                    throw new CompilerException("unexpected while0", token);
                j = new JmpInstruction(InstructionCodes.Br, "br", _compiler.Bits, BuildLabelName());
                _conditionStack.Push(new Condition(ConditionType.While, [j], WordPc));
                i = j;
                break;
            case "again":
                if (!_conditionStack.TryPop(out c) || c.Type != ConditionType.Begin)
                    throw new CompilerException("unexpected again", token);
                j = new JmpInstruction(InstructionCodes.Jmp, "jmp", _compiler.Bits, c.Label);
                j.Offset = c.Pc - WordPc;
                i = j;
                UpdateJumps(c, j.Size);
                break;
            case "repeat":
                if (!_conditionStack.TryPop(out var w) || w.Type != ConditionType.While)
                    throw new CompilerException("unexpected repeat", token);
                if (!_conditionStack.TryPop(out c) || c.Type != ConditionType.Begin)
                    throw new CompilerException("while without begin", token);
                j = new JmpInstruction(InstructionCodes.Jmp, "jmp", _compiler.Bits, c.Label);
                if (_nextLabel != "")
                    j.Labels.Add(_nextLabel);
                j.Offset = c.Pc - WordPc;
                w.I[0].Offset = WordPc + j.Size - w.Pc;
                _nextLabel = w.I[0].JmpTo;
                UpdateJumps(c, j.Size);
                return j;
            case "until":
                if (!_conditionStack.TryPop(out c) || c.Type != ConditionType.Begin)
                    throw new CompilerException("unexpected until", token);
                j = new JmpInstruction(InstructionCodes.Br, "br", _compiler.Bits, c.Label);
                j.Offset = c.Pc - WordPc;
                i = j;
                UpdateJumps(c, j.Size);
                break;
            case "until0":
                if (!_conditionStack.TryPop(out c) || c.Type != ConditionType.Begin)
                    throw new CompilerException("unexpected until0", token);
                j = new JmpInstruction(InstructionCodes.Br0, "br0", _compiler.Bits, c.Label);
                j.Offset = c.Pc - WordPc;
                i = j;
                UpdateJumps(c, j.Size);
                break;
            case "do":
                var d = new OpcodeInstruction((uint)InstructionCodes.PstackPush, "do");
                if (_nextLabel != "")
                    d.Labels.Add(_nextLabel);
                _nextLabel = BuildLabelName();
                _conditionStack.Push(new Condition(ConditionType.Do, [], WordPc, _nextLabel));
                return d;
            case "loop":
                if (!_conditionStack.TryPop(out c) || c.Type != ConditionType.Do)
                    throw new CompilerException("unexpected loop", token);
                j = new LoopInstruction(_compiler.Bits, c.Label);
                j.Offset = c.Pc + 1 - WordPc;
                i = j;
                UpdateJumps(c, j.Size);
                break;
            case "+loop":
                if (!_conditionStack.TryPop(out c) || c.Type != ConditionType.Do)
                    throw new CompilerException("unexpected +loop", token);
                j = new PLoopInstruction(_compiler.Bits, c.Label);
                j.Offset = c.Pc + 1 - WordPc;
                i = j;
                UpdateJumps(c, j.Size);
                break;
            case "leave":
                c = _conditionStack
                    .LastOrDefault(cn => cn!.Type == ConditionType.Do || cn.Type == ConditionType.Begin, null);
                if (c == null)
                    throw new CompilerException("unexpected leave", token);
                j = new JmpInstruction(InstructionCodes.Jmp, "jmp", _compiler.Bits, "leave");
                j.Offset = WordPc;
                c.I.Add(j);
                i = j;
                break;
            case "exit":
                j = new JmpInstruction(InstructionCodes.Jmp, "jmp", _compiler.Bits, "exit");
                j.Offset = WordPc;
                _exitInstructions.Add(j);
                i = j;
                //todo
                break;
            case "locals":
                var t = _compiler.GetName(start);
                start++;
                _locals = t.Word.Split(',');
                i = new Opcode2Instruction((uint)InstructionCodes.Locals, (uint)_locals.Length, $"locals {_locals.Length}");
                break;
            default:
                i = CompileLoopVariableGet(token.Word);
                if (i == null)
                {
                    i = CompileLocalVariableOperation(token.Word);
                    if (i == null)
                    {
                        if (_compiler.ConstantsAndVariables.TryGetValue(token.Word, out var value))
                            i = new PushDataInstruction(token.Word, value, _compiler.Bits);
                        else
                            i = CompileCall(token.Word);
                    }
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
    
    private string BuildLabelName()
    {
        _currentLabelNumber++;
        return $"{CurrentWord}_l{_currentLabelNumber}";
    }

    private Instruction BuildRetInstruction()
    {
        return _locals.Length == 0
            ? new OpcodeInstruction((uint)InstructionCodes.Ret, "ret")
            : new Opcode2Instruction((uint)InstructionCodes.Retn, (uint)_locals.Length, $"retn {_locals.Length}");
    }
    
    private Instruction? CompileLoopVariableGet(string word)
    {
        return word switch
        {
            "I" => new Opcode2Instruction((uint)InstructionCodes.PstackGet, 0, "pstack_get I"),
            "J" => new Opcode2Instruction((uint)InstructionCodes.PstackGet, 2, "pstack_get J"),
            "K" => new Opcode2Instruction((uint)InstructionCodes.PstackGet, 4, "pstack_get K"),
            _ => null
        };
    }

    private void UpdateJumps(Condition c, int jSize)
    {
        foreach (var j in c.I)
            j.Offset = WordPc + jSize - j.Offset;
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
        return new LabelInstruction(InstructionCodes.Call, "call", word, _compiler.Bits);
    }
    
    internal Instruction? Compile(Token token, ref int start)
    {
        switch (token.Type)
        {
            case TokenType.Number:
                var i = new PushDataInstruction("", (int)token.IntValue!, _compiler.Bits);
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

}