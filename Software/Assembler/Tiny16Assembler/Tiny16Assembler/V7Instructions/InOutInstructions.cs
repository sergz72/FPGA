using GenericAssembler;

namespace Tiny16Assembler.V7Instructions;

public class InInstructionCreator: InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        if (parameters.Count != 3 || parameters[0].Type != TokenType.Name || parameters[2].Type != TokenType.Number ||
            !parameters[1].IsChar(',') || !GetRegisterNumber(compiler, parameters[0].StringValue, out var registerNumber))
            throw new InstructionException("register name and port number expected");
        if (parameters[2].LongValue is > 255 or < 0)
            throw new InstructionException("port number is out of range");
        return new ThreeBytesInstruction(line, file, lineNo, InstructionCodes.In, (uint)parameters[2].LongValue, registerNumber);
    }
}

public class OutInstructionCreator: InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        if (parameters.Count != 3 || parameters[0].Type != TokenType.Number || parameters[2].Type != TokenType.Name ||
            !parameters[1].IsChar(',') || !GetRegisterNumber(compiler, parameters[2].StringValue, out var registerNumber))
            throw new InstructionException("port number and register name expected");
        if (parameters[0].LongValue is > 255 or < 0)
            throw new InstructionException("port number is out of range");
        return new ThreeBytesInstruction(line, file, lineNo, InstructionCodes.Out, registerNumber, (uint)parameters[0].LongValue);
    }
}