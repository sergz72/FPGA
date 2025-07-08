using GenericAssembler;

namespace Tiny16Assembler.V6Instructions;

internal sealed class MovInstructionCreator : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        if (parameters.Count < 3)
            throw new InstructionException("two parameters expected");
        if (parameters[0].IsChar('@'))
            return CreateMovrm(compiler, parameters, line, file, lineNo);
        if (parameters[0].Type == TokenType.Name &&
            GetRegisterNumber(compiler, parameters[0].StringValue, out var registerNumber))
            return CreateMovr(compiler, registerNumber, parameters, line, file, lineNo);
        throw new InstructionException("invalid mov instruction");
    }

    private static Instruction CreateMovrm(ICompiler compiler, List<Token> parameters, string line, string file, int lineNo)
    {
        if (parameters[1].Type != TokenType.Name ||
            !GetRegisterNumber(compiler, parameters[1].StringValue, out var registerNumber))
            throw new InstructionException("register name expected");
        if (!parameters[2].IsChar(','))
            throw new InstructionException(", expected");
        if (parameters.Count != 4 || parameters[3].Type != TokenType.Name ||
            !GetRegisterNumber(compiler, parameters[3].StringValue, out var registerNumber2))
            throw new InstructionException("register name2 expected");
        return new OpCode7Instruction(line, file, lineNo, InstructionCodes.Movrm, registerNumber, registerNumber2);
    }

    private static Instruction CreateMovmr(ICompiler compiler, uint registerNumber, List<Token> parameters, string line, string file, int lineNo)
    {
        if (parameters.Count != 4 || parameters[3].Type != TokenType.Name ||
            !GetRegisterNumber(compiler, parameters[3].StringValue, out var registerNumber2))
            throw new InstructionException("register name expected");
        return new OpCode7Instruction(line, file, lineNo, InstructionCodes.Movmr, registerNumber, registerNumber2);
    }
    
    private static Instruction CreateMovr(ICompiler compiler, uint registerNumber, List<Token> parameters, string line, string file, int lineNo)
    {
        if (!parameters[1].IsChar(','))
            throw new InstructionException(", expected");
        if (parameters[2].IsChar('@'))
            return CreateMovmr(compiler, registerNumber, parameters, line, file, lineNo);
        if (parameters[2].Type == TokenType.Name &&
            GetRegisterNumber(compiler, parameters[2].StringValue, out var registerNumber2))
            return new OpCode7Instruction(line, file, lineNo, InstructionCodes.Movrr, registerNumber, registerNumber2);
        var start = 2;
        var immediate = compiler.CalculateExpression(parameters, ref start);
        var instruction = new LoadImmediateInstruction(line, file, lineNo, registerNumber);
        (compiler as Tiny16V6Compiler)?.RegisterInstructionForImmediate(instruction, (uint)immediate);
        return instruction;
    }
}
