using GenericAssembler;

namespace Tiny16Assembler.V7Instructions;

public class LoadInstructionCreator(uint opCode): InInstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        if (parameters.Count != 4 || parameters[1].Type != TokenType.Symbol || parameters[1].StringValue != "," ||
            parameters[2].Type != TokenType.Symbol || parameters[2].StringValue != "@" ||
            parameters[0].Type != TokenType.Name || !GetRegisterNumber(compiler, parameters[0].StringValue, out var registerNumber1) ||
            parameters[3].Type != TokenType.Name || !GetRegisterNumber(compiler, parameters[3].StringValue, out var registerNumber2))
            throw new InstructionException($"invalid load instruction");
        return new ThreeBytesInstruction(line, file, lineNo, opCode, registerNumber2, registerNumber1);
    }
}

public class StoreInstructionCreator(uint opCode): InInstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        if (parameters.Count != 4 || parameters[2].Type != TokenType.Symbol || parameters[2].StringValue != "," ||
            parameters[0].Type != TokenType.Symbol || parameters[0].StringValue != "@" ||
            parameters[1].Type != TokenType.Name || !GetRegisterNumber(compiler, parameters[1].StringValue, out var registerNumber1) ||
            parameters[3].Type != TokenType.Name || !GetRegisterNumber(compiler, parameters[3].StringValue, out var registerNumber2))
            throw new InstructionException($"invalid store instruction");
        return new ThreeBytesInstruction(line, file, lineNo, opCode, registerNumber2, registerNumber1);
    }
}