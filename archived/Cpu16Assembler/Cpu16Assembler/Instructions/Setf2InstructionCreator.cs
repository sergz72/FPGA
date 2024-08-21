using GenericAssembler;

namespace Cpu16Assembler.Instructions;

public class Setf2InstructionCreator(uint v): InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, List<Token> parameters)
    {
        return new AluImmediateInstruction(line, AluOperations.Setf2, 0, v);
    }
}