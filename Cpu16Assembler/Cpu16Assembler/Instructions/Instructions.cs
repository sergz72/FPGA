namespace Cpu16Assembler.Instructions;

internal static class InstructionCodes
{
    internal const uint JmpAddr = 0;
    internal const uint JmpcAddr = 1;
    internal const uint JmpzAddr = 2;
    internal const uint JmpReg = 0x10;
    internal const uint JmpcReg = 0x11;
    internal const uint JmpzReg = 0x12;

    internal const uint CallAddr = 0x20;
    internal const uint CallcAddr = 0x21;
    internal const uint CallzAddr = 0x22;
    internal const uint CallReg = 0x30;
    internal const uint CallcReg = 0x31;
    internal const uint CallzReg = 0x32;

    internal const uint Nop = 0x0040;
    internal const uint Ret = 0x0041;
    internal const uint Retc = 0x0042;
    internal const uint Retz = 0x0043;
    internal const uint Hlt = 0x005F;

    internal const uint MovImmediate = 0x0000;
    internal const uint MovReg = 0x0001;
}

internal class InstructionException(string message) : Exception(message);

internal abstract class Instruction
{
    internal string? RequiredLabel { get; init; }
    
    internal abstract uint BuildCode(ushort labelAddress);

}

internal abstract class InstructionCreator
{
    internal abstract Instruction Create(ICompiler compiler, List<Token> parameters);
    
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

internal sealed class OpCodeInstruction(uint opCode) : Instruction
{
    internal override uint BuildCode(ushort labelAddress)
    {
        return opCode;
    }
}

internal sealed class OpCodeInstructionCreator(uint opCode) : InstructionCreator
{
    internal override Instruction Create(ICompiler compiler, List<Token> parameters)
    {
        if (parameters.Count != 0)
            throw new ParserException("unexpected instruction parameters");
        return new OpCodeInstruction(opCode);
    }
}