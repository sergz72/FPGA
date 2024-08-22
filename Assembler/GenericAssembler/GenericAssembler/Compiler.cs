namespace GenericAssembler;

public enum OutputFormat
{
    Hex,
    Bin
}

public interface ICompiler
{
    int CalculateExpression(List<Token> tokens, ref int start);
    string FindRegisterNumber(string registerName);
    int FindConstantValue(string name);
    void RaiseException(string errorMessage);
}

public class GenericCompiler: ICompiler
{
    protected record BinaryItem(uint Code, string Line);
    
    protected sealed class CompilerException(string fileName, int lineNo, string message) : Exception($"Error in {fileName}:{lineNo}: {message}");

    protected readonly Dictionary<string, InstructionCreator> InstructionCreators;
    protected readonly Dictionary<string, ushort> Labels = [];
    protected readonly List<Instruction> Instructions = [];
    protected readonly IParser Parser;
    protected string CurrentFileName = "";
    protected int CurrentLineNo;
    protected ushort Pc;
    protected readonly List<string> Sources;
    protected readonly string OutputFileName;
    protected readonly OutputFormat OutputFileFormat;
    protected readonly Dictionary<string, int> Constants = [];
    protected readonly Dictionary<string, string> RegisterNames = [];
    protected bool Skip = false;
    protected bool AllowElse = false;
    protected ExpressionParser EParser;

    public GenericCompiler(List<string> sources, string outputFileName, OutputFormat outputFormat,
                            Dictionary<string, InstructionCreator> instructionCreators, IParser parser)
    {
        Sources = sources;
        OutputFileName = outputFileName;
        OutputFileFormat = outputFormat;
        InstructionCreators = instructionCreators;
        Parser = parser;
        EParser = new ExpressionParser(256, this);
    }

    public GenericCompiler()
    {
        Sources = [];
        OutputFileName = "";
        OutputFileFormat = OutputFormat.Hex;
        InstructionCreators = [];
        Parser = new GenericParser();
        EParser = new ExpressionParser(256, this);
    }

    public void RaiseException(string errorMessage) => throw new CompilerException(CurrentFileName, CurrentLineNo, errorMessage);

    public int FindConstantValue(string name)
    {
        if (!Constants.TryGetValue(name, out var result))
            throw new CompilerException(CurrentFileName, CurrentLineNo, $"undefined constant name: {name}");
        return result;
    }

    public string FindRegisterNumber(string registerName)
    {
        return RegisterNames.GetValueOrDefault(registerName, registerName);
    }

    public int CalculateExpression(List<Token> tokens, ref int start)
    {
        return EParser.Parse(tokens, ref start);
    }
    
    public void Compile()
    {
        Pc = 0;
        foreach (var source in Sources)
            Compile(source);
        var binary = CreateBinary();
        using var output = new FileStream(OutputFileName, FileMode.Create);
        switch (OutputFileFormat)
        {
            case OutputFormat.Hex:
            {
                using var writer = new StreamWriter(output);
                var pc = 0;
                foreach (var data in binary)
                {
                    writer.Write($"{data.Code:x8} // {pc:x4} {data.Line}\n");
                    pc++;
                }
                break;
            }
            case OutputFormat.Bin:
            {
                using var writer = new BinaryWriter(output);
                foreach (var data in binary)
                    writer.Write(data.Code);
                break;
            }
        }
    }

    protected List<BinaryItem> CreateBinary()
    {
        var bytes = new List<BinaryItem>();
        foreach (var instruction in Instructions)
        {
            var labelAddress = instruction.RequiredLabel != null ? Labels[instruction.RequiredLabel] : (ushort)0;
            bytes.Add(new BinaryItem(instruction.BuildCode(labelAddress), instruction.Line));
        }
        return bytes;
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
                        switch (tokens[0].StringValue)
                        {
                            case ".equ":
                                CompileEqu(tokens[1..]);
                                break;
                            case ".def":
                                CompileDef(tokens[1..]);
                                break;
                            case ".include":
                                CompileInclude(tokens[1..]);
                                break;
                            case ".if":
                                CompileIf(tokens[1..]);
                                break;
                            default:
                                if (tokens.Count >= 2 && tokens[1].IsChar(':')) // label
                                {
                                    if (!Labels.TryAdd(tokens[0].StringValue, Pc))
                                        throw new CompilerException(fileName, CurrentLineNo, "duplicate label");
                                    if (tokens.Count == 2)
                                        continue;
                                    tokens = tokens[2..];
                                }

                                var instruction = ParseInstruction(line, tokens);
                                Instructions.Add(instruction);
                                Pc++;
                                break;
                        }
                    }
                    break;
            }
        }
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
    
    protected void CompileEqu(List<Token> tokens)
    {
        if (tokens.Count < 2 || tokens[0].Type != TokenType.Name)
            throw new CompilerException(CurrentFileName, CurrentLineNo, "syntax error");
        var name = tokens[0].StringValue;
        if (Constants.ContainsKey(name))
            throw new CompilerException(CurrentFileName, CurrentLineNo, $"constant with name {name} already defined");
        var start = 1;
        var value = CalculateExpression(tokens, ref start);
        Constants.Add(name, value);
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
    
    protected Instruction ParseInstruction(string line, List<Token> tokens)
    {
        if (tokens[0].Type != TokenType.Name)
            throw new CompilerException(CurrentFileName, CurrentLineNo, "instruction name expected");
        
        try
        {
            if (!InstructionCreators.TryGetValue(tokens[0].StringValue, out var creator))
                throw new Exception("unknown instruction: " + tokens[0].StringValue);
            return creator.Create(this, line, tokens[1..]);
        }
        catch (Exception e)
        {
            throw new CompilerException(CurrentFileName, CurrentLineNo, e.Message);
        }
    }
}