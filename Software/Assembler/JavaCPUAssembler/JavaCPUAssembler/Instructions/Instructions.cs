using GenericAssembler;

namespace JavaCPUAssembler.Instructions;

internal static class Conditions
{
    internal const uint Neg = 4;
    internal const uint None = 4;
    internal const uint LT = 2;
    internal const uint GE = 2 + 4;
    internal const uint EQ = 1;
    internal const uint NE = 1 + 4;
    internal const uint GT = 1 + 2 + 4; // not LT & not EQ
    internal const uint LE = 1 + 2; // LT | EQ
    internal const uint CMP_GT = 2;
    internal const uint CMP_EQ = 1;
    internal const uint CMP_NE = 1 + 4;
    internal const uint CMP_LE = 2 + 4;
    internal const uint CMP_LT = 1 + 2 + 4; // not GT & not EQ
    internal const uint CMP_GE = 1 + 2; // GT | EQ
}

internal static class AluOperations
{
    internal const uint Add = 0;
    internal const uint Sub = 1;
    internal const uint And = 2;
    internal const uint Or = 3;
    internal const uint Xor = 4;
    internal const uint Shl = 5;
    internal const uint LLShr = 6;
    internal const uint ILShr = 7;
    internal const uint AShr = 8;
    internal const uint BitTest = 9;
    internal const uint Mul = 10;
    internal const uint Cmp = 11;
}

internal static class InstructionCodes
{
    internal const uint Push = 0;
    internal const uint PushLong = 1;
    internal const uint Dup = 2;
    internal const uint Set = 3;
    internal const uint SetLong = 4;
    internal const uint Jmp = 5;
    internal const uint Get = 6;
    internal const uint GetLong = 7;
    internal const uint Call = 8;
    internal const uint CallIndirect = 9;
    internal const uint Ret = 10;
    internal const uint Retn = 11;
    internal const uint Hlt = 12;
    internal const uint Wfi = 13;
    internal const uint Neg = 14;
    internal const uint Inc = 15;
    internal const uint Reti = 16;
    internal const uint Drop = 17;
    internal const uint Drop2 = 18;
    internal const uint Swap = 19;
    internal const uint Rot = 20;
    internal const uint Over = 21;
    internal const uint LocalGet = 22;
    internal const uint LocalSet = 23;
    internal const uint Locals = 24;
    internal const uint Nop = 25;
    internal const uint GetDataStackPointer = 26;
    internal const uint IfCmp = 27;
    internal const uint If = 28;
    internal const uint AluOp = 29;
    internal const uint Arrayp = 30;
    internal const uint Arrayp2 = 31;
    internal const uint BPush = 32;
    internal const uint SPush = 33;
}

internal sealed class OpCodeInstruction(string line, string file, int lineNo, uint opCode, uint parameter = 0) :
    Instruction(line, file, lineNo)
{
    public override uint[] BuildCode(uint labelAddress, uint pc)
    {
        return [(opCode << 8) | (parameter & 0xFF)];
    }
}

internal sealed class OpCodesInstruction : Instruction
{
    private readonly uint _opCode;
    private readonly uint[] _parameters;
    
    internal OpCodesInstruction(string line, string file, int lineNo, uint opCode, params uint[] parameters) :
        base(line, file, lineNo)
    {
        _opCode = opCode;
        _parameters = parameters;
        Size = (uint)(parameters.Length + 1);
    }
    
    public override uint[] BuildCode(uint labelAddress, uint pc)
    {
        List<uint> code = [_opCode];
        code.AddRange(_parameters);
        return code.ToArray();
    }
}

internal sealed class OpCodeInstructionCreator(uint opCode, uint parameter = 0) : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        if (parameters.Count != 0)
            throw new InstructionException("unexpected instruction parameters");
        return new OpCodeInstruction(line, file, lineNo, opCode, parameter);
    }
}
