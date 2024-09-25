using GenericAssembler;

namespace Tiny16Assembler.Instructions;

internal sealed class JmpInstruction: Instruction
{
    internal JmpInstruction(string line, uint opcode, uint condition, uint address) : base(line)
    {
    }

    public override uint[] BuildCode(uint labelAddress)
    {
        throw new NotImplementedException();
    }
}

internal sealed class JmpInstructionCreator : InstructionCreator
{
    internal JmpInstructionCreator(bool call, uint condition)
    {
        
    }
    public override Instruction Create(ICompiler compiler, string line, List<Token> parameters)
    {
        throw new NotImplementedException();
    }
}
