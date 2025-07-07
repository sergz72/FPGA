using GenericAssembler;

namespace Tiny16Assembler.V6Instructions;

internal sealed class LoadImmediateInstruction : Instruction
{
    private readonly uint _registerNumber;
    internal LoadImmediateInstruction(string line, string file, int lineNo, uint registerNumber): base(line, file, lineNo)
    {
        _registerNumber = registerNumber;
    }
    
    public override uint[] BuildCode(uint labelAddress, uint pc)
    {
        return [(InstructionCodes.Mvi << 13) | (labelAddress << 4) | _registerNumber];
    }
}
