using GenericAssembler;

namespace Tiny16Assembler.Instructions;

internal sealed class Jmp11Instruction: Instruction
{
    internal Jmp11Instruction(string line, uint opcode) : base(line)
    {
    }

    public override uint[] BuildCode(uint labelAddress)
    {
        throw new NotImplementedException();
    }
}

internal sealed class Jmp11InstructionCreator : InstructionCreator
{
    internal Jmp11InstructionCreator(uint opcode)
    {
        
    }
    public override Instruction Create(ICompiler compiler, string line, List<Token> parameters)
    {
        throw new NotImplementedException();
    }
}
