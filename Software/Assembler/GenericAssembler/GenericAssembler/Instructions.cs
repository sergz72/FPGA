namespace GenericAssembler;

public sealed class InstructionException(string message) : Exception(message);

public abstract class Instruction(string line, string file, int lineNo)
{
    public readonly string Line = line;
    public readonly string File = file;
    public readonly int LineNo = lineNo;
    
    public string? RequiredLabel { get; init; }

    public uint Size { get; init; } = 1;
    
    public virtual void UpdateSize(uint labelAddress, uint pc) {}
    
    public abstract uint[] BuildCode(uint labelAddress, uint pc);
}

public abstract class InstructionCreator
{
    public static uint MaxRegNo { get; set;} = 255;
    
    public abstract Instruction? Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters);
    
    public static bool GetRegisterNumber(ICompiler compiler, string parameter, out uint regNo)
    {
        var renamed = compiler.FindRegisterNumber(parameter);
        if ((renamed.StartsWith('r') || renamed.StartsWith('R')) && uint.TryParse(renamed[1..], out regNo))
        {
            if (regNo > MaxRegNo)
                throw new InstructionException("invalid register number");
            return true;
        }
        regNo = 0;
        return false;
    }

    protected static int ReadOffset(ICompiler compiler, List<Token> parameters, ref int start)
    {
        if (start == parameters.Count)
            throw new InstructionException("unexpected end of line");
        return (int)compiler.CalculateExpression(parameters, ref start);
    }
}

internal class DataInstruction : Instruction
{
    private List<uint>? _data;
    internal DataInstruction(string line, string file, int lineNo, List<uint>? data, string? labelName = null) :
        base(line, file, lineNo)
    {
        RequiredLabel = labelName;
        _data = data;
        Size = (uint)(data?.Count ?? 1);
    }
    public override uint[] BuildCode(uint labelAddress, uint pc)
    {
        return _data != null ? _data.ToArray() : [labelAddress];
    }
}