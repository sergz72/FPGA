namespace SZForth;

internal sealed class ForthCompiler
{
    internal enum ArrayStorageType
    {
        Data,
        RoData,
        Bss
    }
    
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
    private readonly Stack<string> _stringStack;
    private readonly Dictionary<string, List<Instruction>> _words;
    private readonly Dictionary<string, int> _wordAddresses;
    private readonly CodeGenerator _codeGenerator;
    private readonly Preprocessor _preprocessor;

    private List<Instruction> _currentWordInstructions, _dataInstructions, _roDataInstructions;

    internal readonly Dictionary<string, int> Constants;
    internal readonly Dictionary<string, Variable> RoDataConstants;
    internal readonly Dictionary<string, Variable> Variables;
    internal readonly ParsedConfiguration Config;
    internal readonly Stack<int> DataStack;
    
    internal bool CompileMode { get; set; }
    internal readonly int Bits;
    
    internal ForthCompiler(ParsedConfiguration config, List<string> sources, int bits)
    {
        Config = config;
        _codeGenerator = new CodeGenerator(this);
        _tokens = new ForthParser(sources.Select(source => new ParserFile(source))).Parse();
        DataStack = new Stack<int>();
        _stringStack = new Stack<string>();
        Bits = bits;
        Constants = new Dictionary<string, int>();
        RoDataConstants = new Dictionary<string, Variable>();
        Variables = new Dictionary<string, Variable>();
        _words = new Dictionary<string, List<Instruction>>();
        _wordAddresses = new Dictionary<string, int>();
        _currentWordInstructions = [];
        _dataInstructions = [];
        _roDataInstructions = [];
        _preprocessor = new Preprocessor(this);
    }
    
    internal CompilerResult Compile()
    {
        _dataInstructions = [];
        _roDataInstructions = [];
        _wordAddresses.Clear();
        DataStack.Clear();
        var start = 0;
        CompileMode = false;
        while (start < _tokens.Count)
        {
            if (_preprocessor.Process(_tokens[start]))
            {
                start++;
                continue;
            }
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
        _preprocessor.Finish();
        Cleanup();
        BuildVariableAddresses();
        BuildRoDataConstants();
        var codeInstructions = BuildCodeInstructions();
        LinkInstructions(codeInstructions, _dataInstructions, _roDataInstructions);
        return new CompilerResult(codeInstructions, _dataInstructions, _roDataInstructions);
    }

    private void BuildRoDataConstants()
    {
        var address = (int)Config.RoData.Address;
        foreach (var c in RoDataConstants)
        {
            c.Value.Address = address;
            address += c.Value.Size;
            BuildRoDataConstant(c.Key, c.Value);
        }
    }

    private void BuildRoDataConstant(string name, Variable v)
    {
        foreach (var c in v.Contents)
            _roDataInstructions.Add(new DataInstruction(name, c));
    }

    private void BuildVariableAddresses()
    {
        var address = (int)Config.Data.Address;
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
        HashSet<string> inUseRoDataConstants = [];
        var oldInUseWords = new HashSet<string>(inUseWords);
        AddToInUseList(inUseWords, inUseVariables, inUseRoDataConstants, Config.Code.EntryPoint);
        foreach (var name in Config.Code.IsrHandlers)
            AddToInUseList(inUseWords, inUseVariables, inUseRoDataConstants, name);
        while (oldInUseWords.Count != inUseWords.Count)
        {
            var toCheck = inUseWords.Except(oldInUseWords).ToList();
            oldInUseWords = new HashSet<string>(inUseWords);
            foreach (var w in toCheck)
                AddToInUseList(inUseWords, inUseVariables, inUseRoDataConstants, w);
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
        toRemove = RoDataConstants.Keys.Where(v => !inUseRoDataConstants.Contains(v)).ToList();
        foreach (var v in toRemove)
        {
            Console.WriteLine($"Remove unused rodata constant {v}");
            RoDataConstants.Remove(v);
        }
    }
    
    private void AddToInUseList(HashSet<string> inUseWords, HashSet<string> inUseVariables,
                                HashSet<string> inUseRoDataConstants, string word)
    {
        foreach (var w in _words[word]
                     .Where(i => i is LabelInstruction)
                     .Select(i => ((LabelInstruction)i).RequiredLabel!))
        {
            if (_words.ContainsKey(w))
                inUseWords.Add(w);
            else if (RoDataConstants.ContainsKey(w))
                inUseRoDataConstants.Add(w);
            else
                inUseVariables.Add(w);
        }
    }
    
    private void LinkInstructions(params List<Instruction>[] instructions)
    {
        foreach (var i in instructions)
            LinkInstructionList(i);
    }
    
    private void LinkInstructionList(List<Instruction> instructions)
    {
        var pc = 0;
        foreach (var instruction in instructions)
        {
            var (address, isData) = instruction.RequiredLabel != null ? GetLabelAddress(instruction.RequiredLabel) : (0, true);
            if (instruction is LabelInstruction li)
                li.IsData = isData;
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
                DataStack.Push((int)token.IntValue!);
                start++;
                break;
            case TokenType.String:
                _stringStack.Push(token.Word);
                start++;
                break;
            default:
                if (Constants.TryGetValue(token.Word, out var value))
                {
                    DataStack.Push(value);
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
                InterpretArrayDefinition(ArrayStorageType.Bss, ref start);
                break;
            case "iarray":
                InterpretArrayDefinition(ArrayStorageType.Data, ref start);
                break;
            case "carray":
                InterpretArrayDefinition(ArrayStorageType.RoData, ref start);
                break;
            case "constant":
                InterpretConstantDefinition(ref start);
                break;
            case "sconstant":
                InterpretStringConstantDefinition(ref start);
                break;
            case "+":
                v1 = DataStack.Pop();
                v2 = DataStack.Pop();
                DataStack.Push(v2 + v1);
                break;
            case "-":
                v1 = DataStack.Pop();
                v2 = DataStack.Pop();
                DataStack.Push(v2 - v1);
                break;
            case "*":
                v1 = DataStack.Pop();
                v2 = DataStack.Pop();
                DataStack.Push(v2 * v1);
                break;
            case "/":
                v1 = DataStack.Pop();
                v2 = DataStack.Pop();
                DataStack.Push(v2 / v1);
                break;
            case "lshift":
                v1 = DataStack.Pop();
                v2 = DataStack.Pop();
                DataStack.Push(v2 << v1);
                break;
            case "rshift":
                v1 = DataStack.Pop();
                v2 = DataStack.Pop();
                DataStack.Push(v2 >> v1);
                break;
            case "and":
                v1 = DataStack.Pop();
                v2 = DataStack.Pop();
                DataStack.Push(v2 & v1);
                break;
            case "or":
                v1 = DataStack.Pop();
                v2 = DataStack.Pop();
                DataStack.Push(v2 | v1);
                break;
            case "xor":
                v1 = DataStack.Pop();
                v2 = DataStack.Pop();
                DataStack.Push(v2 ^ v1);
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
        Variables.Add(t.Word, new Variable(1, init ? [DataStack.Pop()] : []));
        start++;
    }

    private void InterpretArrayDefinition(ArrayStorageType storageType, ref int start)
    {
        var t = GetName(start);
        CheckName(t);
        start++;
        var v = GetNumber(start++);
        List<int> contents = [];
        if (storageType != ArrayStorageType.Bss)
        {
            for (var i = 0; i < v; i++)
                contents.Add(DataStack.Pop());
            contents.Reverse();
        }
        if (storageType == ArrayStorageType.RoData)
            RoDataConstants.Add(t.Word, new Variable(v, contents.ToArray()));
        else
            Variables.Add(t.Word, new Variable(v, contents.ToArray()));
    }
    
    private void InterpretConstantDefinition(ref int start)
    {
        var t = GetName(start);
        CheckName(t);
        Constants.Add(t.Word, DataStack.Pop());
        start++;
    }

    private void InterpretStringConstantDefinition(ref int start)
    {
        var t = GetName(start);
        CheckName(t);
        RoDataConstants.Add(t.Word, BuildStringConstant(_stringStack.Pop()));
        start++;
    }

    private static Variable BuildStringConstant(string s)
    {
        List<int> contents = [s.Length];
        foreach (var c in s)
            contents.Add(c);
        return new Variable(s.Length + 1, contents.ToArray());
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

    // returns address and is_data flag
    private (int, bool) GetLabelAddress(string? requiredLabel)
    {
        if (requiredLabel == null)
            return (0, true);
        if (Constants.TryGetValue(requiredLabel, out var address))
            return (address, true);
        if (Variables.TryGetValue(requiredLabel, out var v))
            return ((int)v.Address!, true);
        if (_wordAddresses.TryGetValue(requiredLabel, out address))
            return (address, false);
        if (RoDataConstants.TryGetValue(requiredLabel, out v))
            return ((int)v.Address!, true);
        throw new CompilerException($"{requiredLabel} not found");
    }

    private static string BuildMapRow(string name, int pc, string pcFormat)
    {
        var spc = pc.ToString(pcFormat);
        return $"{name}: {spc}";
    }
    
    internal List<string> BuildMapFile(string pcFormat)
    {
        List<string> lines = ["code:"];
        lines.AddRange(_wordAddresses
            .OrderBy(wa => wa.Value)
            .Select(wa => BuildMapRow(wa.Key, wa.Value, pcFormat)));
        if (Variables.Count != 0)
        {
            lines.Add("");
            lines.Add("data/bss:");
            lines.AddRange(Variables
                .OrderBy(v => v.Value.Address)
                .Select(v => BuildMapRow(v.Key, (int)v.Value.Address!, pcFormat)));
        }
        if (RoDataConstants.Count != 0)
        {
            lines.Add("");
            lines.Add("rodata:");
            lines.AddRange(RoDataConstants
                .OrderBy(v => v.Value.Address)
                .Select(v => BuildMapRow(v.Key, (int)v.Value.Address!, pcFormat)));
        }
        return lines;
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
