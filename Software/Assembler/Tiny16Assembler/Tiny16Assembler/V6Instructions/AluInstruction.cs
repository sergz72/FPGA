using GenericAssembler;

namespace Tiny16Assembler.V6Instructions;

internal sealed class AluInstructionCreator(uint opCode) : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        if (parameters.Count != 3)
            throw new InstructionException("incorrect ALU instruction");
        if (!parameters[1].IsChar(','))
            throw new InstructionException(", expected");
        if (parameters[0].Type != TokenType.Name ||
            !GetRegisterNumber(compiler, parameters[0].StringValue, out var registerNumber))
            throw new InstructionException("register name expected");
        if (parameters[2].Type == TokenType.Name &&
            GetRegisterNumber(compiler, parameters[2].StringValue, out var registerNumber2))
            return new OpCode3Instruction(line, file, lineNo, InstructionCodes.AluOp, opCode, registerNumber2, registerNumber);
        var start = 2;
        var immediate = compiler.CalculateExpression(parameters, ref start);
        if (immediate is < 0 or > 0x3F)
            throw new InstructionException("immediate is out of range for ALU instruction");
        return new OpCode2Instruction(line, file, lineNo, InstructionCodes.AluOpi,  (uint)immediate, opCode, registerNumber);
    }
}

internal sealed class AluWithImmediateInstructionCreator(uint opCode, int immediate) : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        if (parameters.Count != 1 || parameters[0].Type != TokenType.Name ||
            !GetRegisterNumber(compiler, parameters[0].StringValue, out var registerNumber))
            throw new InstructionException("register name expected");
        var uimmediate = (uint)immediate & 0x3F;
        return new OpCode2Instruction(line, file, lineNo, InstructionCodes.AluOpi,  uimmediate, opCode, registerNumber);
    }
}

internal sealed class AluOneRegisterInstructionCreator(uint opCode) : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        if (parameters.Count != 1 || parameters[0].Type != TokenType.Name ||
            !GetRegisterNumber(compiler, parameters[0].StringValue, out var registerNumber))
            throw new InstructionException("register name expected");
        return new OpCode3Instruction(line, file, lineNo, InstructionCodes.AluOp, opCode, registerNumber, registerNumber);
    }
}
