using GenericAssembler;

namespace Tiny16Assembler.V7Instructions;

public class InInstructionCreator: InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        if (parameters.Count < 3 || parameters[0].Type != TokenType.Name ||
            !parameters[1].IsChar(',') || !GetRegisterNumber(compiler, parameters[0].StringValue, out var registerNumber))
            throw new InstructionException("register name and port number expected");
        var start = 2;
        var portNumber = compiler.CalculateExpression(parameters, ref start);
        if (portNumber is > 255 or < 0)
            throw new InstructionException("port number is out of range");
        return new ThreeBytesInstruction(line, file, lineNo, InstructionCodes.In, (uint)portNumber, registerNumber);
    }
}

public class OutInstructionCreator: InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        if (parameters.Count < 3)
            throw new InstructionException("port number and register name expected");
        var start = 0;
        var portNumber = compiler.CalculateExpression(parameters, ref start);
        if (parameters.Count != start + 2 || parameters[start+1].Type != TokenType.Name ||
            !parameters[start].IsChar(',') || !GetRegisterNumber(compiler, parameters[start+1].StringValue, out var registerNumber))
            throw new InstructionException("port number and register name expected");
        if (portNumber is > 255 or < 0)
            throw new InstructionException("port number is out of range");
        return new ThreeBytesInstruction(line, file, lineNo, InstructionCodes.Out, registerNumber, (uint)portNumber);
    }
}
