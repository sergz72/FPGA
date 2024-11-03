namespace SZForth;

internal sealed class ForthCompiler
{
    internal class Variable
    {
        internal readonly int Size;
        internal readonly int[] Contents;
        internal int? Address { get; set; }

        internal Variable(int size, int[] contents)
        {
            Size = size;
            Contents = contents;
            Address = null;
        }
    }
    
    private readonly List<Token> _tokens;
    private readonly Stack<int> _dataStack;
    private readonly Dictionary<string, List<Instruction>> _words;
    private readonly Dictionary<string, int> _wordAddresses;
    private readonly CodeGenerator _codeGenerator;

    private List<Instruction> _currentWordInstructions, _dataInstructions, _roDataInstructions;

    internal readonly Dictionary<string, int> Constants;
    internal readonly Dictionary<string, Variable> Variables;
    internal readonly ParsedConfiguration Config;
    
    internal bool CompileMode { get; set; }
    internal readonly int Bits;
    
    internal ForthCompiler(ParsedConfiguration config, List<string> sources, int bits)
    {
        _codeGenerator = new CodeGenerator(this);
        Config = config;
        _tokens = new ForthParser(sources.Select(source => new ParserFile(source))).Parse();
        _dataStack = new Stack<int>();
        Bits = bits;
        Constants = new Dictionary<string, int>();
        Variables = new Dictionary<string, Variable>();
        _words = new Dictionary<string, List<Instruction>>();
        _wordAddresses = new Dictionary<string, int>();
        _currentWordInstructions = [];
        _dataInstructions = [];
        _roDataInstructions = [];
    }
    
    internal CompilerResult Compile()
    {
        _dataInstructions = [];
        _roDataInstructions = [];
        _wordAddresses.Clear();
        _dataStack.Clear();
        var start = 0;
        CompileMode = false;
        while (start < _tokens.Count)
        {
            if (CompileMode)
            {
                var token = _tokens[start++];
                var i = _codeGenerator.Compile(token, ref start);
                if (i != null)
                {
                    _codeGenerator.WordPc += i.Size;
                    _currentWordInstructions.Add(i);
                }

                if (!CompileMode)
                {
                    _currentWordInstructions[0].Labels.Add(_codeGenerator.CurrentWord);
                    _words.Add(_codeGenerator.CurrentWord, _currentWordInstructions);
                }
            }
            else
                Interpret(ref start);
        }
        Cleanup();
        BuildVariableAddresses();
        var codeInstructions = BuildCodeInstructions();
        LinkInstructions(codeInstructions, _dataInstructions, _roDataInstructions);
        return new CompilerResult(codeInstructions, _dataInstructions, _roDataInstructions);
    }

    private void BuildVariableAddresses()
    {
        var address = 0;
        foreach (var variable in Variables.Where(v => v.Value.Contents.Length != 0))
        {
            variable.Value.Address = address;
            address += variable.Value.Size;
            foreach (var v in variable.Value.Contents)
                _dataInstructions.Add(new DataInstruction(variable.Key, v));
        }
        foreach (var variable in Variables.Values.Where(v => v.Contents.Length == 0))
        {
            variable.Address = address;
            address += variable.Size;
        }
    }

    private void Cleanup()
    {
        HashSet<string> inUseWords = [Config.Code.EntryPoint];
        foreach (var name in Config.Code.IsrHandlers)
            inUseWords.Add(name);
        HashSet<string> inUseVariables = [];
        var oldInUseWords = new HashSet<string>(inUseWords);
        AddToInUseList(inUseWords, inUseVariables, Config.Code.EntryPoint);
        foreach (var name in Config.Code.IsrHandlers)
            AddToInUseList(inUseWords, inUseVariables, name);
        while (oldInUseWords.Count != inUseWords.Count)
        {
            var toCheck = inUseWords.Except(oldInUseWords).ToList();
            oldInUseWords = new HashSet<string>(inUseWords);
            foreach (var w in toCheck)
                AddToInUseList(inUseWords, inUseVariables, w);
        }

        var toRemove = _words.Keys.Where(w => !inUseWords.Contains(w)).ToList();
        foreach (var w in toRemove)
        {
            Console.WriteLine($"Remove unused word {w}");
            _words.Remove(w);
        }
        toRemove = Variables.Keys.Where(v => !inUseVariables.Contains(v)).ToList();
        foreach (var v in toRemove)
        {
            Console.WriteLine($"Remove unused variable {v}");
            Variables.Remove(v);
        }
    }
    
    private void AddToInUseList(HashSet<string> inUseWords, HashSet<string> inUseVariables, string word)
    {
        foreach (var w in _words[word]
                     .Where(i => i is LabelInstruction)
                     .Select(i => ((LabelInstruction)i).RequiredLabel!))
        {
            if (_words.ContainsKey(w))
                inUseWords.Add(w);
            else
                inUseVariables.Add(w);
        }
    }
    
    private void LinkInstructions(List<Instruction> codeInstructions, List<Instruction> dataInstructions,
                                    List<Instruction> roDataInstructions)
    {
        LinkInstructionList(codeInstructions);
        LinkInstructionList(dataInstructions);
        LinkInstructionList(roDataInstructions);
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

        if (Config.Code.IsrHandlers.Length != 0)
        {
            Instruction ins = new LabelInstruction(InstructionCodes.Jmp, "jmp", Config.Code.EntryPoint, Bits);
            result.Add(ins);
            pc += ins.Size;
            ins = new OpcodeInstruction((uint)InstructionCodes.Hlt, "hlt");
            result.Add(ins);
            pc += ins.Size;
        }

        for (var i = 0; i < Config.Code.IsrHandlers.Length - 1; i++)
        {
            Instruction ins = new LabelInstruction(InstructionCodes.Jmp, "jmp", Config.Code.IsrHandlers[i], Bits);
            result.Add(ins);
            pc += ins.Size;
            ins = new OpcodeInstruction((uint)InstructionCodes.Hlt, "hlt");
            result.Add(ins);
            pc += ins.Size;
        }

        if (Config.Code.IsrHandlers.Length != 0)
        {
            var word = Config.Code.IsrHandlers[^1];
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
        if (Config.Code.IsrHandlers.Length != 0)
            return word != Config.Code.IsrHandlers[^1];
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
                if (Constants.TryGetValue(token.Word, out var value))
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

    internal void CheckName(Token t)
    {
        if (Constants.ContainsKey(t.Word) || _words.ContainsKey(t.Word) || Variables.ContainsKey(t.Word))
            throw new CompilerException($"constant/variable/array/word with name {t.Word} already exists", t);
    }
    
    private void InterpretWordDefinition(ref int start)
    {
        var name = GetName(start);
        CheckName(name);
        CompileMode = true;
        _currentWordInstructions = [];
        _codeGenerator.Init(name.Word);
        start++;
    }
    
    private void InterpretVariableDefinition(bool init, ref int start)
    {
        var t = GetName(start);
        CheckName(t);
        Variables.Add(t.Word, new Variable(1, init ? [_dataStack.Pop()] : []));
        start++;
    }

    private void InterpretArrayDefinition(bool init, ref int start)
    {
        var t = GetName(start);
        CheckName(t);
        start++;
        var v = GetNumber(start++);
        List<int> contents = [];
        if (init)
        {
            for (var i = 0; i < v; i++)
                contents.Add(_dataStack.Pop());
        }
        Variables.Add(t.Word, new Variable(v, contents.ToArray()));
    }
    
    private void InterpretConstantDefinition(ref int start)
    {
        var t = GetName(start);
        CheckName(t);
        Constants.Add(t.Word, _dataStack.Pop());
        start++;
    }
    
    internal Token GetName(int start)
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
        if (!Constants.TryGetValue(token.Word, out var value))
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
        if (Constants.TryGetValue(requiredLabel, out var address))
            return address;
        if (Variables.TryGetValue(requiredLabel, out var v))
            return (int)v.Address!;
        if (_wordAddresses.TryGetValue(requiredLabel, out var wordAddress))
            return wordAddress;
        throw new CompilerException($"{requiredLabel} not found");
    }

    private static string BuildMapRow(string name, int pc, string pcFormat)
    {
        var spc = pc.ToString(pcFormat);
        return $"{name}: {spc}";
    }
    
    internal IEnumerable<string> BuildMapFile(string pcFormat)
    {
        return _wordAddresses.OrderBy(wa => wa.Value)
            .Select(wa => BuildMapRow(wa.Key, wa.Value, pcFormat));
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
