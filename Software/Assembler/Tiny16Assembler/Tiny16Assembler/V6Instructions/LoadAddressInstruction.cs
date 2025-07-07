using GenericAssembler;

namespace Tiny16Assembler.V6Instructions;

public class LoadAddressInstructionCreator: InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        if (parameters.Count != 3 || parameters[0].Type != TokenType.Name || parameters[2].Type != TokenType.Name ||
            !parameters[1].IsChar(',') || !GetRegisterNumber(compiler, parameters[0].StringValue, out var registerNumber))
            throw new InstructionException("register name and label name expected");
        var instruction = new LoadImmediateInstruction(line, file, lineNo, registerNumber);
        (compiler as Tiny16V6Compiler)?.RegisterInstructionForLabel(instruction, parameters[2].StringValue);
        return instruction;
    }
}