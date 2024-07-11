namespace Cpu16Assembler.Instructions;

internal static class AluOperations
{
    internal const uint Add = 3;
}

internal static class InstructionCodes
{
    internal const uint JmpAddr = 0;
    internal const uint JmpcAddr = 1;
    internal const uint JmpzAddr = 2;
    internal const uint JmpncAddr = 3;
    internal const uint JmpnzAddr = 4;
    internal const uint JmpReg = 0x10;
    internal const uint JmpcReg = 0x11;
    internal const uint JmpzReg = 0x12;
    internal const uint JmpncReg = 0x13;
    internal const uint JmpnzReg = 0x14;

    internal const uint CallAddr = 0x20;
    internal const uint CallcAddr = 0x21;
    internal const uint CallzAddr = 0x22;
    internal const uint CallncAddr = 0x23;
    internal const uint CallnzAddr = 0x24;
    internal const uint CallReg = 0x30;
    internal const uint CallcReg = 0x31;
    internal const uint CallzReg = 0x32;
    internal const uint CallncReg = 0x33;
    internal const uint CallnzReg = 0x34;

    internal const uint Nop = 0x40;
    internal const uint Ret = 0x41;
    internal const uint Retc = 0x42;
    internal const uint Retz = 0x43;
    internal const uint Retnc = 0x44;
    internal const uint Retnz = 0x45;
    internal const uint Hlt = 0x5F;

    internal const uint MovImmediate = 0x5D;
    internal const uint MovReg = 0x5E;

    internal const uint In = 0xE0;
    internal const uint Out = 0xE1;
}

internal class InstructionException(string message) : Exception(message);

internal abstract class Instruction(string line)
{
    internal readonly string Line = line;
    
    internal string? RequiredLabel { get; init; }
    
    internal abstract uint BuildCode(ushort labelAddress);

}

internal abstract class InstructionCreator
{
    internal abstract Instruction Create(ICompiler compiler, string line, List<Token> parameters);
    
    protected static bool GetRegisterNumber(string parameter, out uint regNo)
    {
        if ((parameter.StartsWith('r') || parameter.StartsWith('R')) && uint.TryParse(parameter[1..], out regNo))
        {
            if (regNo > 255)
                throw new InstructionException("invalid register number");
            return true;
        }
        regNo = 0;
        return false;
    }
}

internal sealed class OpCodeInstruction(string line, uint opCode) : Instruction(line)
{
    internal override uint BuildCode(ushort labelAddress)
    {
        return opCode;
    }
}

internal sealed class OpCodeInstructionCreator(uint opCode) : InstructionCreator
{
    internal override Instruction Create(ICompiler compiler, string line, List<Token> parameters)
    {
        if (parameters.Count != 0)
            throw new InstructionException("unexpected instruction parameters");
        return new OpCodeInstruction(line, opCode);
    }
}