using GenericAssembler;

namespace Cpu16LiteAssembler.Instructions;

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
    internal const uint Setf2 = 13;
    internal const uint Rlc   = 14;
    internal const uint Rrc   = 15;
    internal const uint Shlc  = 16;
    internal const uint Shrc  = 17;
}

internal static class InstructionCodes
{
    internal const uint JmpAddr = 0;
    internal const uint JmpcAddr = 1;
    internal const uint JmpncAddr = 2;
    internal const uint JmpzAddr = 3;
    internal const uint JmpnzAddr = 4;
    internal const uint JmpGtAddr = 5;
    internal const uint JmpLeAddr = 6;
    internal const uint JmpReg = 0x10;
    internal const uint JmpcReg = 0x11;
    internal const uint JmpncReg = 0x12;
    internal const uint JmpzReg = 0x13;
    internal const uint JmpnzReg = 0x14;
    internal const uint JmpGtReg = 0x15;
    internal const uint JmpLeReg = 0x16;

    internal const uint CallAddr = 0xFF20;
    internal const uint CallcAddr = 0xFF21;
    internal const uint CallncAddr = 0xFF22;
    internal const uint CallzAddr = 0xFF23;
    internal const uint CallnzAddr = 0xFF24;
    internal const uint CallGtAddr = 0xFF25;
    internal const uint CallLeAddr = 0xFF26;
    internal const uint CallReg = 0xFF30;
    internal const uint CallcReg = 0xFF31;
    internal const uint CallncReg = 0xFF32;
    internal const uint CallzReg = 0xFF33;
    internal const uint CallnzReg = 0xFF34;
    internal const uint CallGtReg = 0xFF35;
    internal const uint CallLeReg = 0xFF36;

    internal const uint Ret = 0xFF40;
    internal const uint Retc = 0xFF41;
    internal const uint Retnc = 0xFF42;
    internal const uint Retz = 0xFF43;
    internal const uint Retnz = 0xFF44;
    internal const uint RetGt = 0xFF45;
    internal const uint RetLe = 0xFF46;

    internal const uint Reti = 0xFF50;
    internal const uint Retic = 0xFF51;
    internal const uint Retinc = 0xFF52;
    internal const uint Retiz = 0xFF53;
    internal const uint Retinz = 0xFF54;
    internal const uint RetiGt = 0xFF55;
    internal const uint RetiLe = 0xFF56;
    
    internal const uint LoadRp = 0x5A;
    internal const uint Loadf = 0x5B;
    internal const uint Nop = 0x5C;
    internal const uint MovImmediate = 0x5D;
    internal const uint MovReg = 0x5E;
    internal const uint Hlt = 0x5F;

    internal const uint In = 0xF0;
    internal const uint InRp = 0xF1;
    internal const uint InRpInc = 0xF2;
    internal const uint InRpDec = 0xF3;
    internal const uint Out = 0xF4;
    internal const uint OutRpInc = 0xF5;
    internal const uint OutRpDec = 0xF6;

    internal const uint MovRpImmediate = 0xE0;
    internal const uint MovRpImmediateRpInc = 0xE1;
    internal const uint MovRpImmediateRpDec = 0xE2;

    internal const uint MovRpRegister = 0xE4;
    internal const uint MovRpRegisterRpInc = 0xE5;
    internal const uint MovRpRegisterRpDec = 0xE6;
    
    internal const uint MovRegisterRp = 0xE8;
    internal const uint MovRegisterRpRpInc = 0xE9;
    internal const uint MovRegisterRpRpDec = 0xEA;
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