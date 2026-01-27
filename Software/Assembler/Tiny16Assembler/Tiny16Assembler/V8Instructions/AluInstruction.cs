using GenericAssembler;

namespace Tiny16Assembler.V8Instructions;

internal sealed class AluInstructionCreator(uint opCode) : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        if (parameters.Count < 3)
            throw new InstructionException("incorrect ALU instruction");
        if (!parameters[1].IsChar(','))
            throw new InstructionException(", expected");
        if (parameters[0].Type != TokenType.Name ||
            !GetRegisterNumber(compiler, parameters[0].StringValue, out var registerNumber))
            throw new InstructionException("register name expected");
        if (parameters[2].Type == TokenType.Name &&
            GetRegisterNumber(compiler, parameters[2].StringValue, out var registerNumber2))
            return new ThreeBytesInstruction(line, file, lineNo, InstructionCodes.AluOp|opCode, registerNumber2, registerNumber);
        var start = 2;
        var immediate = compiler.CalculateExpression(parameters, ref start);
        if (immediate is >= -128 and <= 127)
            return new ThreeBytesInstruction(line, file, lineNo, InstructionCodes.AluOp|opCode|InstructionCodes.Imm8, 
                registerNumber, (uint)immediate);
        if (immediate is < -32768 or > 65535)
            throw new InstructionException("immediate is out of range for ALU instruction");
        immediate &= 0xFFFF;
        return new FourBytesInstruction(line, file, lineNo, InstructionCodes.AluOp|opCode|InstructionCodes.Imm16, 
            registerNumber, (uint)(immediate & 0xFF), (uint)(immediate >> 8));
    }
}
