namespace GenericAssembler;

public sealed class InstructionException(string message) : Exception(message);

public abstract class Instruction(string line)
{
    public readonly string Line = line;
    
    public string? RequiredLabel { get; init; }
    
    public abstract uint BuildCode(ushort labelAddress);
}

public abstract class InstructionCreator
{
    public abstract Instruction Create(ICompiler compiler, string line, List<Token> parameters);
    
    protected static bool GetRegisterNumber(string parameter, out uint regNo)
    {
        if ((parameter.StartsWith('r') || parameter.StartsWith('R')) && uint.TryParse(parameter[1..], out regNo))
        {
            if (regNo > 255)
                throw new InstructionException("invalid register number");
            return true;
        }
        regNo = 0;
        return false;
    }

    protected static bool GetRegisterNumberWithIoFlag(List<Token> parameters, ref int start, out uint regNo, out bool io)
    {
        io = false;
        if (parameters[start].IsChar('['))
        {
            io = true;
            start++;
        }

        if (start == parameters.Count)
            throw new InstructionException("unexpected end of line");

        if (parameters[start].Type != TokenType.Name ||
            !GetRegisterNumber(parameters[start].StringValue, out regNo))
        {
            if (io) throw new InstructionException("register name expected");
            regNo = 0;
            return false;
        }

        start++;
        
        if (!io)
            return true;

        if (start == parameters.Count || !parameters[start].IsChar(']'))
            throw new InstructionException("] expected");
        start++;
        
        return true;
    }
}
