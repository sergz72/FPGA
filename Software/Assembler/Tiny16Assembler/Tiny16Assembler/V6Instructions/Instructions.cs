using GenericAssembler;

namespace Tiny16Assembler.V6Instructions;

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
    //opcode3
    internal const uint Br = 0;
    internal const uint Jmp = 1;
    internal const uint AluOp = 3;
    internal const uint Call = 4;
    internal const uint Mvi = 5;

    //opcode2
    internal const uint AluOpi = 3;
    
    //opcode7
    internal const uint Hlt = 0x20;
    internal const uint Nop = 0x22;
    internal const uint Wfi = 0x21;
    internal const uint Movrr = 0x22;
    internal const uint Ret = 0x23;
    internal const uint Reti = 0x24;
    internal const uint LoadSp = 0x25;
    internal const uint Push = 0x26;
    internal const uint Pop = 0x27;
    internal const uint Movmr = 0x28;
    internal const uint Movrm = 0x29;
    internal const uint In = 0x2A;
    internal const uint Out = 0x2B;
    internal const uint LoadPc = 0x2C;
    internal const uint RCall = 0x2D;

    //alu operations
    internal const uint Adc = 0;
    internal const uint Add = 1;
    internal const uint Sbc = 2;
    internal const uint Sub = 3;
    internal const uint Cmp = 4;
    internal const uint And = 5;
    internal const uint Test = 6;
    internal const uint Or = 7;
    internal const uint Xor = 8;
    internal const uint Shl = 9;
    internal const uint Shr = 10;
    internal const uint Rol = 11;
    internal const uint Ror = 12;
    internal const uint Mul = 15;
}

internal sealed class OpCode3Instruction(string line, string file, int lineNo, uint opCode, uint param, uint src, uint dst) :
    Instruction(line, file, lineNo)
{
    public override uint[] BuildCode(uint labelAddress, uint pc)
    {
        return [(opCode << 13) | (param << 8) | (src << 4) | dst];
    }
}

internal sealed class OpCode7Instruction(string line, string file, int lineNo, uint opCode, uint src, uint dst) :
    Instruction(line, file, lineNo)
{
    public override uint[] BuildCode(uint labelAddress, uint pc)
    {
        return [(opCode << 9) | (src << 4) | dst];
    }
}

internal sealed class OpCode2Instruction(string line, string file, int lineNo, uint opCode, uint data, uint alu_op, uint dst) :
    Instruction(line, file, lineNo)
{
    public override uint[] BuildCode(uint labelAddress, uint pc)
    {
        return [(opCode << 14) | ((data & 0x30) << 8) | (alu_op << 8) | ((data & 0x0F) << 4) | dst];
    }
}

internal sealed class OpCode7InstructionCreator(uint opCode) : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        if (parameters.Count != 0)
            throw new InstructionException("unexpected instruction parameters");
        return new OpCode7Instruction(line, file, lineNo, opCode, 0, 0);
    }
}
