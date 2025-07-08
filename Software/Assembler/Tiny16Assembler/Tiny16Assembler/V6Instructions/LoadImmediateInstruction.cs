using GenericAssembler;

namespace Tiny16Assembler.V6Instructions;

internal sealed class LoadImmediateInstruction : Instruction
{
    private readonly uint _registerNumber;
    private uint _value;
    internal LoadImmediateInstruction(string line, string file, int lineNo, uint registerNumber): base(line, file, lineNo)
    {
        _registerNumber = registerNumber;
    }
    
    public override uint[] BuildCode(uint labelAddress, uint pc)
    {
        return [(InstructionCodes.Mvi << 13) | (_value << 4) | _registerNumber];
    }

    internal void SetValue(uint value)
    {
        _value = value;
    }
}
