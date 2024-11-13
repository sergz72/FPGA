namespace GenericAssembler;

public enum OutputFormat
{
    Hex,
    Bin
}

public interface ICompiler
{
    long CalculateExpression(List<Token> tokens, ref int start);
    string FindRegisterNumber(string registerName);
    void AddConstant(string name, long value);
    long FindConstantValue(string name);
    uint? FindLabel(string name);
    void RaiseException(string errorMessage);
    Token GetNextToken(List<Token> tokens, ref int start);
}

public class GenericCompiler: ICompiler
{
    protected record BinaryItem(uint[] Code, string Line);
    
    internal sealed class CompilerException(string fileName, int lineNo, string message) : Exception($"Error in {fileName}:{lineNo}: {message}");

    protected readonly Dictionary<string, InstructionCreator> InstructionCreators;
    protected readonly Dictionary<string, uint> Labels = [];
    protected readonly Dictionary<string, List<Instruction>> Instructions = [];
    protected readonly IParser Parser;
    protected readonly List<string> Sources;
    protected readonly OutputFormat OutputFileFormat;
    protected readonly Dictionary<string, long> Constants = [];
    protected readonly Dictionary<string, string> RegisterNames = [];
    protected readonly uint CodeSize;
    protected readonly uint PcSize;
    protected readonly uint DataSize;
    protected readonly Dictionary<string, uint> Pc = [];
    protected readonly Dictionary<string, uint> StartAddress = [];
    protected readonly Linker L;
    protected string CurrentFileName = "";
    protected int CurrentLineNo;
    protected bool Skip = false;
    protected bool AllowElse = false;
    protected ExpressionParser EParser;
    protected string CurrentSection;

    public GenericCompiler(List<string> sources, OutputFormat outputFormat,
                            Dictionary<string, InstructionCreator> instructionCreators, IParser parser,
                            uint codeSize = 8, uint pcSize = 4, uint dataSize = 8)
    {
        Sources = sources.Where(s => !s.EndsWith(".ld")).ToList();
        L = new Linker(sources.FirstOrDefault(s => s.EndsWith(".ld")));
        OutputFileFormat = outputFormat;
        InstructionCreators = instructionCreators;
        Parser = parser;
        CodeSize = codeSize;
        PcSize = pcSize;
        DataSize = dataSize;
        EParser = new ExpressionParser(256, this);
    }

    public GenericCompiler()
    {
        Sources = [];
        L = new Linker(null);
        OutputFileFormat = OutputFormat.Hex;
        InstructionCreators = [];
        Parser = new GenericParser();
        EParser = new ExpressionParser(256, this);
    }
    
    public void RaiseException(string errorMessage) => throw new CompilerException(CurrentFileName, CurrentLineNo, errorMessage);

    public long FindConstantValue(string name)
    {
        if (!Constants.TryGetValue(name, out var result))
            throw new CompilerException(CurrentFileName, CurrentLineNo, $"undefined constant name: {name}");
        return result;
    }

    public uint? FindLabel(string name)
    {
        return Labels.TryGetValue(name, out var address) ? address : null;
    }

    public string FindRegisterNumber(string registerName)
    {
        return RegisterNames.GetValueOrDefault(registerName, registerName);
    }

    public long CalculateExpression(List<Token> tokens, ref int start)
    {
        return EParser.Parse(tokens, ref start);
    }

    public Token GetNextToken(List<Token> tokens, ref int start)
    {
        if (start == tokens.Count)
            throw new CompilerException(CurrentFileName, CurrentLineNo, "unexpected end of line");
        return tokens[start++];
    }
    
    public void Compile()
    {
        Pc.Clear();
        Instructions.Clear();
        SetSegment("code");
        foreach (var source in Sources)
            Compile(source);
        foreach (var instructions in Instructions)
        {
            if (instructions.Value.Count == 0)
                continue;
            var binary = CreateBinary(instructions.Key);
            using var output = new FileStream(L.GetFileName(instructions.Key, OutputFileFormat), FileMode.Create);
            switch (OutputFileFormat)
            {
                case OutputFormat.Hex:
                {
                    using var writer = new StreamWriter(output);
                    var pc = 0;
                    foreach (var data in binary)
                    {
                        foreach (var code in data.Code)
                        {
                            var codes = code.ToString("x" + (instructions.Key == "code" ? CodeSize : DataSize));
                            var pcs = pc.ToString("x" + PcSize);
                            writer.Write($"{codes} // {pcs} {data.Line}\n");
                            pc++;
                        }
                    }

                    break;
                }
                case OutputFormat.Bin:
                {
                    using var writer = new BinaryWriter(output);
                    foreach (var data in binary)
                    {
                        foreach (var code in data.Code)
                            writer.Write(code);
                    }

                    break;
                }
            }
        }
    }

    protected List<BinaryItem> CreateBinary(string section)
    {
        var retries = 10000;
        uint pc = StartAddress[section];
        while (retries > 0)
        {
            var again = false;
            foreach (var instruction in Instructions[section])
            {
                if (instruction.RequiredLabel != null)
                {
                    var labelAddress = Labels[instruction.RequiredLabel];
                    var size = instruction.Size;
                    instruction.UpdateSize(labelAddress, pc);
                    var diff = instruction.Size - size;
                    if (diff != 0)
                    {
                        UpdateLabelAddresses(pc, diff);
                        again = true;
                        break;
                    }
                }
                pc += instruction.Size;
            }
            retries = again ? retries - 1 : -1;
        }
        if (retries == 0)
            throw new CompilerException("CreateBinary", 0, "Instructions size update was unsuccessful.");

        var bytes = new List<BinaryItem>();
        pc = StartAddress[section];
        foreach (var instruction in Instructions[section])
        {
                var labelAddress = instruction.RequiredLabel != null ? Labels[instruction.RequiredLabel] : 0;
                var code = instruction.BuildCode(labelAddress, pc);
                pc += (uint)code.Length;
                bytes.Add(new BinaryItem(code, instruction.Line));
        }

        return bytes;
    }

    private void UpdateLabelAddresses(uint pc, uint diff)
    {
        var original = new Dictionary<string, uint>(Labels);
        foreach (var label in original)
        {
            if (label.Value > pc)
                Labels[label.Key] = label.Value + diff;
        }
    }

    public void Compile(string fileName, string[]? inLines = null)
    {
        CurrentFileName = fileName;
        CurrentLineNo = 0;
        
        var lines = inLines ?? File.ReadAllLines(fileName);
        
        foreach (var line in lines)
        {
            CurrentLineNo++;
            var tokens = Parser.Parse(line);
            if (tokens.Count == 0)
                continue;

            if (tokens.Count >= 2 && tokens[1].IsChar(':')) // label
            {
                if (tokens[0].Type != TokenType.Name)
                    throw new CompilerException(fileName, CurrentLineNo, "unexpected token " + tokens[0]);
                if (!Labels.TryAdd(tokens[0].StringValue, Pc[CurrentSection]))
                    throw new CompilerException(fileName, CurrentLineNo, "duplicate label");
                if (tokens.Count == 2)
                    continue;
                tokens = tokens[2..];
            }
            
            if (tokens[0].Type != TokenType.Name)
                throw new CompilerException(fileName, CurrentLineNo, "unexpected token " + tokens[0]);
            switch (tokens[0].StringValue)
            {
                case ".else":
                    CompileElse(tokens[1..]);
                    break;
                case ".endif":
                    CompileEndif(tokens[1..]);
                    break;
                default:
                    if (!Skip)
                    {
                        Instruction i;
                        switch (tokens[0].StringValue)
                        {
                            case ".equ":
                                CompileEqu(tokens[1..]);
                                break;
                            case ".def":
                                CompileDef(tokens[1..]);
                                break;
                            case ".segment":
                                CompileSegment(tokens[1..]);
                                break;
                            case ".include":
                                CompileInclude(tokens[1..]);
                                break;
                            case ".if":
                                CompileIf(tokens[1..]);
                                break;
                            case "dw":
                                i = CompileData(line, fileName, 2, tokens[1..]);
                                Instructions[CurrentSection].Add(i);
                                Pc[CurrentSection] += i.Size;
                                break;
                            case "db":
                                i = CompileData(line, fileName, 1, tokens[1..]);
                                Instructions[CurrentSection].Add(i);
                                Pc[CurrentSection] += i.Size;
                                break;
                            case "dd":
                                i = CompileData(line, fileName, 4, tokens[1..]);
                                Instructions[CurrentSection].Add(i);
                                Pc[CurrentSection] += i.Size;
                                break;
                            case "resw":
                                var start = 1;
                                var value = CalculateExpression(tokens, ref start);
                                if (value <= 0)
                                    throw new CompilerException(fileName, CurrentLineNo, "invalid number of words");
                                Pc[CurrentSection] += (uint)value;
                                break;
                            default:
                                var instruction = ParseInstruction(line, fileName, CurrentLineNo, tokens);
                                if (instruction != null)
                                {
                                    Instructions[CurrentSection].Add(instruction);
                                    Pc[CurrentSection] += instruction.Size;
                                }
                                break;
                        }
                    }
                    break;
            }
        }
    }

    private Instruction CompileData(string line, string fileName, int size, List<Token> tokens)
    {
        var start = 0;
        List<uint> result = [];
        while (start < tokens.Count)
        {
            if (tokens[start].Type == TokenType.String)
            {
                foreach (var c in tokens[start].StringValue)
                    result.Add(c);
                start++;
            }
            else if (tokens[start].Type == TokenType.Name && !Constants.ContainsKey(tokens[start].StringValue)) // label
               return new DataInstruction(line, fileName, CurrentLineNo, null, tokens[start].StringValue); 
            else // constant
            {
                var value = CalculateExpression(tokens, ref start);
                result.Add((uint)value);
                if (start < tokens.Count && !tokens[start++].IsChar(','))
                    throw new CompilerException(fileName, CurrentLineNo, ", expected");
            }
        }
        return new DataInstruction(line, fileName, CurrentLineNo, result);
    }

    private void CompileInclude(List<Token> tokens)
    {
        if (tokens.Count != 1 || tokens[0].Type != TokenType.String)
            throw new CompilerException(CurrentFileName, CurrentLineNo, "file name expected");
        var savedFileName = CurrentFileName;
        var savedLineNo = CurrentLineNo;
        Compile(tokens[0].StringValue);
        CurrentFileName = savedFileName;
        CurrentLineNo = savedLineNo;
    }

    private void CompileIf(List<Token> tokens)
    {
        var start = 0;
        var value = CalculateExpression(tokens, ref start);
        Skip = value == 0;
        AllowElse = true;
    }

    private void CompileElse(List<Token> tokens)
    {
        if (!AllowElse)
            throw new CompilerException(CurrentFileName, CurrentLineNo, "unexpected else");
        AllowElse = false;
        Skip = !Skip;
    }

    private void CompileEndif(List<Token> tokens)
    {
        Skip = false;
    }

    public void AddConstant(string name, long value)
    {
        if (!Constants.TryAdd(name, value))
            throw new CompilerException(CurrentFileName, CurrentLineNo, $"constant with name {name} already defined");
    }
    
    protected void CompileEqu(List<Token> tokens)
    {
        if (tokens.Count < 2 || tokens[0].Type != TokenType.Name)
            throw new CompilerException(CurrentFileName, CurrentLineNo, "syntax error");
        var name = tokens[0].StringValue;
        var start = 1;
        var value = CalculateExpression(tokens, ref start);
        AddConstant(name, value);
    }

    protected void CompileDef(List<Token> tokens)
    {
        if (tokens.Count != 2 || tokens[0].Type != TokenType.Name || tokens[1].Type != TokenType.Name)
            throw new CompilerException(CurrentFileName, CurrentLineNo, "syntax error");
        var name = tokens[0].StringValue;
        if (RegisterNames.ContainsKey(name))
            throw new CompilerException(CurrentFileName, CurrentLineNo, $"register with name {name} already defined");
        var rname = tokens[1].StringValue;
        RegisterNames.Add(name, rname);
    }

    protected void SetSegment(string segmentName)
    {
        var (name, address) = L.GetSectionNameAndAddress(segmentName);
        CurrentSection = name;
        Instructions.TryAdd(CurrentSection, []);
        Pc.TryAdd(CurrentSection, address);
        StartAddress[CurrentSection] = address;
    }

    protected void CompileSegment(List<Token> tokens)
    {
        if (tokens.Count != 1 || tokens[0].Type != TokenType.Name)
            throw new CompilerException(CurrentFileName, CurrentLineNo, "segment name expected");
        SetSegment(tokens[0].StringValue);
    }

    protected Instruction? ParseInstruction(string line, string file, int lineNo, List<Token> tokens)
    {
        if (tokens[0].Type != TokenType.Name)
            throw new CompilerException(CurrentFileName, CurrentLineNo, "instruction name expected");
        
        try
        {
            if (!InstructionCreators.TryGetValue(tokens[0].StringValue, out var creator))
                throw new Exception("unknown instruction: " + tokens[0].StringValue);
            return creator.Create(this, line, file, lineNo, tokens[1..]);
        }
        catch (Exception e)
        {
            throw new CompilerException(CurrentFileName, CurrentLineNo, e.Message);
        }
    }
}