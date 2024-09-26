using GenericAssembler;

namespace Tiny16Assembler.Instructions;

internal sealed class AluInstruction: Instruction
{
    internal AluInstruction(string line, uint opcode) : base(line)
    {
    }

    public override uint[] BuildCode(uint labelAddress)
    {
        throw new NotImplementedException();
    }
}

internal sealed class AluInstructionCreator : InstructionCreator
{
    internal AluInstructionCreator(uint opId)
    {
        
    }
    public override Instruction Create(ICompiler compiler, string line, List<Token> parameters)
    {
        throw new NotImplementedException();
    }
}
