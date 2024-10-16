﻿namespace GenericAssembler;

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
    uint? FindLabel(string name);
    void RaiseException(string errorMessage);
    Token GetNextToken(List<Token> tokens, ref int start);
}

public class GenericCompiler: ICompiler
{
    protected record BinaryItem(uint[] Code, string Line);
    
    protected sealed class CompilerException(string fileName, int lineNo, string message) : Exception($"Error in {fileName}:{lineNo}: {message}");

    protected readonly Dictionary<string, InstructionCreator> InstructionCreators;
    protected readonly Dictionary<string, uint> Labels = [];
    protected readonly List<Instruction> Instructions = [];
    protected readonly IParser Parser;
    protected readonly List<string> Sources;
    protected readonly string OutputFileName;
    protected readonly OutputFormat OutputFileFormat;
    protected readonly Dictionary<string, int> Constants = [];
    protected readonly Dictionary<string, string> RegisterNames = [];
    protected readonly uint CodeSize;
    protected readonly uint PcSize;
    protected string CurrentFileName = "";
    protected int CurrentLineNo;
    protected uint Pc;
    protected bool Skip = false;
    protected bool AllowElse = false;
    protected ExpressionParser EParser;

    public GenericCompiler(List<string> sources, string outputFileName, OutputFormat outputFormat,
                            Dictionary<string, InstructionCreator> instructionCreators, IParser parser,
                            uint codeSize = 8, uint pcSize = 4)
    {
        Sources = sources;
        OutputFileName = outputFileName;
        OutputFileFormat = outputFormat;
        InstructionCreators = instructionCreators;
        Parser = parser;
        CodeSize = codeSize;
        PcSize = pcSize;
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

    public uint? FindLabel(string name)
    {
        return Labels.TryGetValue(name, out var address) ? address : null;
    }

    public string FindRegisterNumber(string registerName)
    {
        return RegisterNames.GetValueOrDefault(registerName, registerName);
    }

    public int CalculateExpression(List<Token> tokens, ref int start)
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
                    foreach (var code in data.Code)
                    {
                        var codes = code.ToString("x" + CodeSize);
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

    protected List<BinaryItem> CreateBinary()
    {
        var retries = 10000;
        uint pc = 0;
        while (retries > 0)
        {
            var again = false;
            foreach (var instruction in Instructions)
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
        pc = 0;
        foreach (var instruction in Instructions)
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

                                var instruction = ParseInstruction(line, fileName, CurrentLineNo, tokens);
                                Instructions.Add(instruction);
                                Pc += instruction.Size;
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
    
    protected Instruction ParseInstruction(string line, string file, int lineNo, List<Token> tokens)
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