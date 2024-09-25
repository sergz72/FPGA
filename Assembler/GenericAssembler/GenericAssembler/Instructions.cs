namespace GenericAssembler;

public sealed class InstructionException(string message) : Exception(message);

public abstract class Instruction(string line)
{
    public readonly string Line = line;
    
    public string? RequiredLabel { get; init; }

    public uint Size { get; init; } = 1;
    
    public virtual void UpdateSize(uint labelAddress, uint pc) {}
    
    public abstract uint[] BuildCode(uint labelAddress);
}

public abstract class InstructionCreator
{
    public static uint MaxRegNo { get; set;} = 255;
    
    public abstract Instruction Create(ICompiler compiler, string line, List<Token> parameters);
    
    protected static bool GetRegisterNumber(ICompiler compiler, string parameter, out uint regNo)
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

    protected static void ReadOffset(ICompiler compiler, List<Token> parameters, ref int start, out int offset)
    {
        if (start == parameters.Count)
            throw new InstructionException("unexpected end of line");
        offset = compiler.CalculateExpression(parameters, ref start);
    }
}
