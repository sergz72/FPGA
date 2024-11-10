using GenericAssembler;

namespace Tiny16Assembler.V2Instructions;

internal sealed class IntInstruction: Instruction
{
    private readonly uint _address;
    
    internal IntInstruction(string line, string file, int lineNo, uint address) : base(line, file, lineNo)
    {
        _address = address;
    }

    public override uint[] BuildCode(uint labelAddress, uint pc)
    {
        return [(InstructionCodes.Int << 10) | _address];
    }
}

internal sealed class IntInstructionCreator : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        throw new NotImplementedException();
    }
}
