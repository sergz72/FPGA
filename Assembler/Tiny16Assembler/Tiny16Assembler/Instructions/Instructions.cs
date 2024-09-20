using GenericAssembler;

namespace Tiny16Assembler.Instructions;

internal static class AluOperations
{
    internal const uint Test = 0;
    internal const uint Neg = 1;
    internal const uint Add = 2;
    internal const uint Adc = 3;
    internal const uint Sub = 4;
    internal const uint Sbc = 5;
    internal const uint Shl = 6;
    internal const uint Shr = 7;
    internal const uint And = 8;
    internal const uint Or  = 9;
    internal const uint Xor = 10;
    internal const uint Cmp = 11;
    internal const uint Setf = 12;
    internal const uint Rlc   = 13;
    internal const uint Rrc   = 14;
    internal const uint Shlc  = 15;
    internal const uint Shrc  = 16;

    internal const uint Mul = 29;
    internal const uint Div = 30;
    internal const uint Rem = 31;
}

internal static class InstructionCodes
{
    internal const uint Hlt = 0;
    internal const uint Nop = 1;
    internal const uint Reti = 2;
    internal const uint Pushf = 3;

    internal const uint Jmp = 0x18;
    internal const uint Call = 0x28;
    // condition = neg,c,z,n
    internal const uint Jmpc = 0x14;
    internal const uint Jmpnc = 0x1C;
    internal const uint Jmpz = 0x12;
    internal const uint Jmpnz = 0x1A;
    internal const uint Jmpmi = 0x11;
    internal const uint Jmppl = 0x19;
    internal const uint Callc = 0x14;
    internal const uint Callnc = 0x1C;
    internal const uint Callz = 0x12;
    internal const uint Callnz = 0x1A;
    internal const uint Callmi = 0x11;
    internal const uint Callpl = 0x19;
}

internal sealed class OpCodeInstruction(string line, uint opCode) : Instruction(line)
{
    public override uint BuildCode(ushort labelAddress)
    {
        return opCode;
    }
}

internal sealed class OpCodeInstructionCreator(uint opCode) : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, List<Token> parameters)
    {
        if (parameters.Count != 0)
            throw new InstructionException("unexpected instruction parameters");
        return new OpCodeInstruction(line, opCode);
    }
}