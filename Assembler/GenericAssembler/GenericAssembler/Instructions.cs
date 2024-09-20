namespace GenericAssembler;

public sealed class InstructionException(string message) : Exception(message);

public abstract class Instruction(string line)
{
    public readonly string Line = line;
    
    public string? RequiredLabel { get; init; }

    public uint Size { get; init; } = 1;
    
    public abstract uint[] BuildCode(uint labelAddress);
}

public abstract class InstructionCreator
{
    public abstract Instruction Create(ICompiler compiler, string line, List<Token> parameters);
    
    protected static bool GetRegisterNumber(ICompiler compiler, string parameter, out uint regNo)
    {
        var renamed = compiler.FindRegisterNumber(parameter);
        if ((renamed.StartsWith('r') || renamed.StartsWith('R')) && uint.TryParse(renamed[1..], out regNo))
        {
            if (regNo > 255)
                throw new InstructionException("invalid register number");
            return true;
        }
        regNo = 0;
        return false;
    }

    private static void ReadOffset(ICompiler compiler, List<Token> parameters, ref int start, out int offset)
    {
        if (start == parameters.Count)
            throw new InstructionException("unexpected end of line");
        offset = compiler.CalculateExpression(parameters, ref start);
    }

    protected static bool GetRegisterNumberWithIoFlag(ICompiler compiler, List<Token> parameters, ref int start, bool withOffset,
                                                        out uint regNo, out int offset, out bool io)
    {
        if (start == parameters.Count)
            throw new InstructionException("unexpected end of line");

        io = false;
        if (parameters[start].IsChar('['))
        {
            io = true;
            start++;
        }

        if (start == parameters.Count)
            throw new InstructionException("unexpected end of line");

        if (parameters[start].Type != TokenType.Name ||
            !GetRegisterNumber(compiler, parameters[start].StringValue, out regNo))
        {
            if (io) throw new InstructionException("register name expected");
            regNo = 0;
            offset = 0;
            return false;
        }

        start++;

        if (!io)
        {
            offset = 0;
            return true;
        }

        if (withOffset)
        {
            if (start == parameters.Count)
                throw new InstructionException("unexpected end of line");

            if (parameters[start].IsChar('+'))
            {
                start++;
                ReadOffset(compiler, parameters, ref start, out offset);
            }
            else if (parameters[start].IsChar('-'))
            {
                start++;
                ReadOffset(compiler, parameters, ref start, out var off);
                offset = -off;
            }
            else
                offset = 0;
        }
        else
            offset = 0;

        if (start == parameters.Count || !parameters[start].IsChar(']'))
            throw new InstructionException("] expected");
        start++;
        
        return true;
    }
}
