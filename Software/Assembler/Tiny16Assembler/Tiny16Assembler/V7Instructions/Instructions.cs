using GenericAssembler;

namespace Tiny16Assembler.V7Instructions;

internal static class Conditions
{
    internal const uint None = 8;
    internal const uint C = 4;
    internal const uint Z = 2;
    internal const uint MI = 1; // N
    internal const uint NC = 4 + 8;
    internal const uint NZ = 2 + 8;
    internal const uint PL = 1 + 8; // not N
    internal const uint GT = 4 + 2 + 8; // not C & not Z
    internal const uint LE = 4 + 2; // C | Z
}

internal static class InstructionCodes
{
    internal const uint Br = 0x1C << 2;
    internal const uint Jmp = 0x1B << 2;
    internal const uint Jal = 0x1A << 2;
    internal const uint RJmp = 0x19 << 2;
    internal const uint Jalr = 0x18 << 2;

    internal const uint Out = 0x17 << 2;
    internal const uint In = 0x16 << 2;

    internal const uint Sw = 0x15 << 2;
    internal const uint Sb = 0x14 << 2;
    internal const uint Lw = 0x13 << 2;
    internal const uint Lb = 0x12 << 2;
    
    internal const uint Hlt = 0;
    internal const uint Wfi = 1 << 2;
    internal const uint Reti = 2 << 2;

    internal const uint AluOp = 128;
    internal const uint Imm16 = 64;
    internal const uint Imm8 = 32;

    //alu operations
    // single operand
    internal const uint Clr = 0;
    internal const uint Set = 1;
    internal const uint Inc = 2;
    internal const uint Dec = 3;
    internal const uint Not = 4;
    internal const uint Neg = 5;
    internal const uint Shl = 6;
    internal const uint Shr = 7;
    internal const uint Rol = 8;
    internal const uint Ror = 9;

    // double operands
    internal const uint Mov = 16;
    internal const uint Adc = 17;
    internal const uint Add = 18;
    internal const uint Sbc = 19;
    internal const uint Sub = 20;
    internal const uint And = 21;
    internal const uint Or = 22;
    internal const uint Xor = 23;

    // double operands, no save
    internal const uint Cmp = 30;
    internal const uint Test = 31;
}

internal sealed class OneByteInstruction(string line, string file, int lineNo, uint opCode) :
    Instruction(line, file, lineNo)
{
    public override uint[] BuildCode(uint labelAddress, uint pc)
    {
        return [opCode];
    }
}

internal sealed class OneByteInstructionCreator(uint opCode) : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        if (parameters.Count != 0)
            throw new InstructionException("unexpected instruction parameters");
        return new OneByteInstruction(line, file, lineNo, opCode);
    }
}

internal sealed class TwoBytesInstruction: Instruction
{
    private readonly uint _opCode, _parameter;

    internal TwoBytesInstruction(string line, string file, int lineNo, uint opCode, uint parameter) :
        base(line, file, lineNo)
    {
        _opCode = opCode;
        _parameter = parameter;
        Size = 2;
    }
    
    public override uint[] BuildCode(uint labelAddress, uint pc)
    {
        return [_opCode, _parameter];
    }
}

internal sealed class ThreeBytesInstruction: Instruction
{
    private readonly uint _opCode, _parameter1, _parameter2;
    
    internal ThreeBytesInstruction(string line, string file, int lineNo, uint opCode, uint parameter1,
        uint parameter2) : base(line, file, lineNo)
    {
        _opCode = opCode;
        _parameter1 = parameter1;
        _parameter2 = parameter2;
        Size = 3;
    }
    
    public override uint[] BuildCode(uint labelAddress, uint pc)
    {
        return [_opCode, _parameter1, _parameter2];
    }
}

internal sealed class FourBytesInstruction: Instruction
{
    private readonly uint _opCode, _parameter1, _parameter2, _parameter3;
    
    internal FourBytesInstruction(string line, string file, int lineNo, uint opCode, uint parameter1,
        uint parameter2, uint parameter3) : base(line, file, lineNo)
    {
        _opCode = opCode;
        _parameter1 = parameter1;
        _parameter2 = parameter2;
        _parameter3 = parameter3;
        Size = 4;
    }
    
    public override uint[] BuildCode(uint labelAddress, uint pc)
    {
        return [_opCode, _parameter1, _parameter2, _parameter3];
    }
}
