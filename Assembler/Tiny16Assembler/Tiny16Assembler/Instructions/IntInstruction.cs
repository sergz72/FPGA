using GenericAssembler;

namespace Tiny16Assembler.Instructions;

internal sealed class IntInstruction: Instruction
{
    private readonly uint _address;
    
    internal IntInstruction(string line, uint address) : base(line)
    {
        _address = address;
    }

    public override uint[] BuildCode(uint labelAddress)
    {
        return [(InstructionCodes.Int << 10) | _address];
    }
}

internal sealed class IntInstructionCreator : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, List<Token> parameters)
    {
        throw new NotImplementedException();
    }
}
