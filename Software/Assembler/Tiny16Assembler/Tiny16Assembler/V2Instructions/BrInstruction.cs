using GenericAssembler;

namespace Tiny16Assembler.V2Instructions;

internal sealed class BrInstruction: Instruction
{
    private readonly uint _condition, _address;
    
    internal BrInstruction(string line, string file, int lineNo, uint condition, uint address) : base(line, file, lineNo)
    {
        _condition = condition;
        _address = address;
    }

    public override uint[] BuildCode(uint labelAddress, uint pc)
    {
        return [(InstructionCodes.Br << 10) | (_address << 4) | _condition];
    }
}

internal sealed class BrInstructionCreator : InstructionCreator
{
    internal BrInstructionCreator(uint condition)
    {
        
    }
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        throw new NotImplementedException();
    }
}
