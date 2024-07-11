using Cpu16Assembler.Instructions;

namespace Cpu16Assembler;

internal enum OutputFormat
{
    Hex,
    Bin
}

internal interface ICompiler
{
    int CalculateExpression(List<Token> tokens);
}
internal sealed class Compiler(List<string> sources, string outputFileName, OutputFormat outputFormat): ICompiler
{
    private record BinaryItem(uint Code, string Line);
    
    private sealed class CompilerException(string fileName, int lineNo, string message) : Exception($"Error in {fileName}:{lineNo}: {message}");
    
    private static readonly Dictionary<string, InstructionCreator> InstructionCreators = new()
    {
        {"nop", new OpCodeInstructionCreator(InstructionCodes.Nop)},
        {"hlt", new OpCodeInstructionCreator(InstructionCodes.Hlt)},
        {"ret", new OpCodeInstructionCreator(InstructionCodes.Ret)},
        {"retc", new OpCodeInstructionCreator(InstructionCodes.Retc)},
        {"retz", new OpCodeInstructionCreator(InstructionCodes.Retz)},
        {"retnc", new OpCodeInstructionCreator(InstructionCodes.Retnc)},
        {"retnz", new OpCodeInstructionCreator(InstructionCodes.Retnz)},
        {"mov", new MovInstructionCreator()},
        {"clr", new RegisterLoadInstructionCreator(0)},
        {"ser", new RegisterLoadInstructionCreator(0xFFFF)},
        {"inc", new AluImmediateInstructionCreator(AluOperations.Add, 1)},
        {"dec", new AluImmediateInstructionCreator(AluOperations.Add, 0xFFFF)},
        {"in", new InOutInstructionCreator(InstructionCodes.In)},
        {"out", new InOutInstructionCreator(InstructionCodes.Out)},
        {"jmp", new JmpInstructionCreator(InstructionCodes.JmpAddr, InstructionCodes.JmpReg)},
        {"jmpc", new JmpInstructionCreator(InstructionCodes.JmpcAddr, InstructionCodes.JmpcReg)},
        {"jmpz", new JmpInstructionCreator(InstructionCodes.JmpzAddr, InstructionCodes.JmpzReg)},
        {"jmpnc", new JmpInstructionCreator(InstructionCodes.JmpncAddr, InstructionCodes.JmpncReg)},
        {"jmpnz", new JmpInstructionCreator(InstructionCodes.JmpnzAddr, InstructionCodes.JmpnzReg)},
        {"call", new JmpInstructionCreator(InstructionCodes.CallAddr, InstructionCodes.CallReg)},
        {"callc", new JmpInstructionCreator(InstructionCodes.CallcAddr, InstructionCodes.CallcReg)},
        {"callz", new JmpInstructionCreator(InstructionCodes.CallzAddr, InstructionCodes.CallzReg)},
        {"callnc", new JmpInstructionCreator(InstructionCodes.CallncAddr, InstructionCodes.CallncReg)},
        {"callnz", new JmpInstructionCreator(InstructionCodes.CallnzAddr, InstructionCodes.CallnzReg)}
    };
    private readonly Dictionary<string, ushort> _labels = [];
    private readonly List<Instruction> _instructions = [];
    private readonly Parser _parser = new();
    private string _currentFileName = "";
    private int _currentLineNo;
    private ushort _pc;

    public int CalculateExpression(List<Token> tokens)
    {
        if (tokens.Count != 1 || tokens[0].Type != TokenType.Number)
            throw new InstructionException("only single number is supported");
        
        var result = tokens[0].IntValue;

        return result;
    }
    
    internal void Compile()
    {
        _pc = 0;
        foreach (var source in sources)
            Compile(source);
        var binary = CreateBinary();
        using var output = new FileStream(outputFileName, FileMode.Create);
        switch (outputFormat)
        {
            case OutputFormat.Hex:
            {
                using var writer = new StreamWriter(output);
                var pc = 0;
                foreach (var data in binary)
                {
                    writer.Write($"{data.Code:x8} // pc={pc:x4} {data.Line}\n");
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

    private List<BinaryItem> CreateBinary()
    {
        var bytes = new List<BinaryItem>();
        foreach (var instruction in _instructions)
        {
            var labelAddress = instruction.RequiredLabel != null ? _labels[instruction.RequiredLabel] : (ushort)0;
            bytes.Add(new BinaryItem(instruction.BuildCode(labelAddress), instruction.Line));
        }
        return bytes;
    }
    
    private void Compile(string fileName)
    {
        _currentFileName = fileName;
        _currentLineNo = 0;
        
        var lines = File.ReadAllLines(fileName);
        
        foreach (var line in lines)
        {
            _currentLineNo++;
            var tokens = _parser.Parse(line);
            if (tokens.Count == 0)
                continue;
            if (tokens[0].Type != TokenType.Name)
                throw new CompilerException(fileName, _currentLineNo, "unexpected token " + tokens[0]);
            switch (tokens[0].StringValue)
            {
                case ".equ":
                    CompileEqu(tokens[1..]);
                    break;
                case ".def":
                    CompileDef(tokens[1..]);
                    break;
                default:
                    if (tokens.Count >= 2 && tokens[1].IsChar(':')) // label
                    {
                        if (!_labels.TryAdd(tokens[0].StringValue, _pc))
                            throw new CompilerException(fileName, _currentLineNo, "duplicate label");
                        if (tokens.Count == 2)
                            continue;
                        tokens = tokens[2..];
                    }
                    var instruction = ParseInstruction(line, tokens);
                    _instructions.Add(instruction);
                    _pc++;
                    break;
            }
        }
    }

    private void CompileEqu(List<Token> tokens)
    {
        throw new NotImplementedException();
    }

    private void CompileDef(List<Token> tokens)
    {
        throw new NotImplementedException();
    }
    
    private Instruction ParseInstruction(string line, List<Token> tokens)
    {
        if (tokens[0].Type != TokenType.Name)
            throw new CompilerException(_currentFileName, _currentLineNo, "instruction name expected");
        
        try
        {
            if (!InstructionCreators.TryGetValue(tokens[0].StringValue, out var creator))
                throw new Exception("unknown instruction: " + tokens[0].StringValue);
            return creator.Create(this, line, tokens[1..]);
        }
        catch (Exception e)
        {
            throw new CompilerException(_currentFileName, _currentLineNo, e.Message);
        }
    }
}