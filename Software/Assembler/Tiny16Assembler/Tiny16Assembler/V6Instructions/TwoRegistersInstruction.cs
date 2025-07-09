using GenericAssembler;

namespace Tiny16Assembler.V6Instructions;

internal sealed class TwoRegistersInstructionCreator(uint opCode, bool useSrc, string name) : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        if (parameters.Count != 4)
            throw new InstructionException($"invalid {name} instruction");
        uint registerNumber1;
        int idx;
        if (parameters[0].IsChar('@'))
        {
            idx = 2;
            if (!useSrc)
                throw new InstructionException("unexpected symbol");
            if (parameters[1].Type != TokenType.Name ||
                !GetRegisterNumber(compiler, parameters[1].StringValue, out registerNumber1))
                throw new InstructionException("register name expected");
        }
        else
        {
            idx = 1;
            if (useSrc || !parameters[2].IsChar('@'))
                throw new InstructionException("@ expected");
            if (parameters[0].Type != TokenType.Name ||
                !GetRegisterNumber(compiler, parameters[0].StringValue, out registerNumber1))
                throw new InstructionException("register name expected");
        }
        if (!parameters[idx].IsChar(','))
            throw new InstructionException(", expected");
        if (parameters[3].Type != TokenType.Name ||
            !GetRegisterNumber(compiler, parameters[3].StringValue, out var registerNumber2))
            throw new InstructionException("register2 name expected");
        return new OpCode7Instruction(line, file, lineNo, opCode, useSrc ? registerNumber1 : registerNumber2,
            useSrc ? registerNumber2 : registerNumber1);
    }
}
