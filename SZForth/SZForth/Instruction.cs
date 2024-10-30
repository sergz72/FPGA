using System.Runtime.Intrinsics;

namespace SZForth;

internal enum InstructionCodes
{
    Push = 0,
    Dup,
    Set,
    Jmp,
    Get,
    Call,
    Ret,
    Hlt,
    Wfi,
    Br,
    Br0,
    Reti,
    Drop,
    Swap,
    Rot,
    AluOp = 0xF0
}

internal enum AluOperations
{
    Add = 0,
    And,
    Or,
    Xor,
    Eq,
    Ne,
    Gt,
    Ge,
    Le,
    Lt,
    Mul,
    Div,
    Rem,
    Sub
}

internal abstract class Instruction(string comment)
{
    internal string? RequiredLabel { get; init; }

    internal uint[]? Code;

    internal List<string> Labels { get; set; } = [];
    
    internal int Size { get; init; } = 1;
    
    internal abstract void BuildCode(int labelAddress, int pc);

    internal IEnumerable<string> BuildCodeLines(string codeFormat, string pcFormat, int pc)
    {
        if (Code == null) throw new InstructionException("null code"); 
        return Code.Select((c, i) => c.ToString(codeFormat) + $" // " + FormatPc(pc + i, pcFormat) + BuildComment(i));
    }

    private string BuildComment(int i)
    {
        if (i != 0)
            return "";
        return " " + comment + string.Join("", Labels.Select(FormatLabel));
    }

    private static string FormatLabel(string label)
    {
        return label == "" ? "" : " ; " + label;
    }

    private static string FormatPc(int pc, string format)
    {
        return pc.ToString(format);
    }
}

internal sealed class InstructionException(string message) : Exception(message);

internal sealed class PushDataInstruction: Instruction
{
    private uint _value;
    private int _bits;
    internal PushDataInstruction(string name, int value, int bits) : base($"push {name} {value} {value:X}")
    {
        Size = 3;
        _bits = bits;
        _value = (uint)value;
    }
    
    internal override void BuildCode(int labelAddress, int pc)
    {
        Code = [(uint)InstructionCodes.Push, (uint)(_value & ((1 << (_bits / 2)) - 1)), _value >> (_bits / 2)];
    }
}

internal sealed class DataInstruction(string name, int value): Instruction($"{name} = {value}")
{
    internal override void BuildCode(int labelAddress, int pc)
    {
        Code = [(uint)value];
    }
}

internal sealed class LabelInstruction: Instruction
{
    private readonly int _bits;
    private readonly InstructionCodes _opCode;

    internal LabelInstruction(InstructionCodes opCode, string name, string label, int bits) : base($"{name} {label}")
    {
        RequiredLabel = label;
        Size = 3;
        _bits = bits;
        _opCode = opCode;
    }
    
    internal override void BuildCode(int labelAddress, int pc)
    {
        Code = [(uint)_opCode, (uint)(labelAddress & ((1 << (_bits / 2)) - 1)), (uint)labelAddress >> (_bits / 2)];
    }
}

internal sealed class OpcodeInstruction(uint opCode, string name) : Instruction(name)
{
    internal override void BuildCode(int labelAddress, int pc)
    {
        Code = [opCode];
    }
}

internal class JmpInstruction: Instruction
{
    private readonly int _bits;
    private readonly InstructionCodes _opCode;
    
    internal int Offset { get; set; }

    internal string JmpTo { get; set; } = "";

    internal JmpInstruction(InstructionCodes opCode, string name, int bits, string jmpTo) : base($"{name} {jmpTo}")
    {
        Size = 3;
        _bits = bits;
        _opCode = opCode;
        JmpTo = jmpTo;
    }

    protected uint V1(int pc) => (uint)(pc & ((1 << (_bits / 2)) - 1));
    protected uint V2(int pc) => (uint)pc >> (_bits / 2);
    
    internal override void BuildCode(int labelAddress, int pc)
    {
        pc += Offset;
        Code = [(uint)_opCode, V1(pc), V2(pc)];
    }
}

internal sealed class OfInstruction: JmpInstruction
{
    internal OfInstruction(int bits, string jmpTo) : base(InstructionCodes.Br, "of (= if drop)", bits, jmpTo)
    {
        Size = 5;
    }
    
    internal override void BuildCode(int labelAddress, int pc)
    {
        pc += Offset;
        Code = [(uint)InstructionCodes.AluOp + (uint)AluOperations.Ne, (uint)InstructionCodes.Br, V1(pc), V2(pc),
                (uint)InstructionCodes.Drop];
    }
}
