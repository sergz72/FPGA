using GenericAssembler;

namespace Tiny16Assembler.Instructions;

internal sealed class BrInstruction: Instruction
{
    private readonly uint _condition, _address;
    
    internal BrInstruction(string line, uint condition, uint address) : base(line)
    {
        _condition = condition;
        _address = address;
    }

    public override uint[] BuildCode(uint labelAddress)
    {
        return [(InstructionCodes.Br << 10) | (_address << 4) | _condition];
    }
}

internal sealed class BrInstructionCreator : InstructionCreator
{
    internal BrInstructionCreator(uint condition)
    {
        
    }
    public override Instruction Create(ICompiler compiler, string line, List<Token> parameters)
    {
        throw new NotImplementedException();
    }
}
