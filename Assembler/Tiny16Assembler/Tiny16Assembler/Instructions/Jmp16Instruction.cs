using GenericAssembler;

namespace Tiny16Assembler.Instructions;

internal sealed class Jmp16Instruction: Instruction
{
    internal Jmp16Instruction(string line, uint opcode, uint condition) : base(line)
    {
    }

    public override uint[] BuildCode(uint labelAddress)
    {
        throw new NotImplementedException();
    }
}

internal sealed class Jmp16InstructionCreator : InstructionCreator
{
    internal Jmp16InstructionCreator(uint opcode, uint condition)
    {
        
    }
    public override Instruction Create(ICompiler compiler, string line, List<Token> parameters)
    {
        throw new NotImplementedException();
    }
}
