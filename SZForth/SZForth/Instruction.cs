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
    Retn,
    Hlt,
    Wfi,
    Br,
    Br0,
    Reti,
    Drop,
    Swap,
    Rot,
    Over,
    Loop,
    PstackPush,
    PstackGet,
    LocalGet,
    LocalSet,
    Locals,
    UpdatePstackPointer,
    AluOp = 0xF0
}

internal enum AluOperations
{
    Add = 0,
    Sub,
    And,
    Or,
    Xor,
    Eq,
    Ne,
    Gt,
    Ge,
    Le,
    Lt,
    Shl,
    Shr,
    Mul,
    Div,
    Rem
}

internal abstract class Instruction
{
    internal string? RequiredLabel { get; init; }

    internal uint[]? Code;

    internal List<string> Labels { get; set; } = [];
    
    internal int Size { get; init; } = 1;
    
    internal abstract void BuildCode(int labelAddress, int pc);

    protected string Comment;
    
    protected Instruction(string comment)
    {
       Comment = comment; 
    }
    
    internal IEnumerable<string> BuildCodeLines(string codeFormat, string pcFormat, int pc)
    {
        if (Code == null) throw new InstructionException("null code"); 
        return Code.Select((c, i) => c.ToString(codeFormat) + $" // " + FormatPc(pc + i, pcFormat) + BuildComment(i));
    }

    private string BuildComment(int i)
    {
        if (i != 0)
            return "";
        return " " + Comment + string.Join("", Labels.Select(FormatLabel));
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
    private InstructionCodes _opCode;

    internal bool IsData
    {
        set
        {
            _opCode = value ? InstructionCodes.Push : InstructionCodes.Call;
            Comment = value ? $"push {RequiredLabel}" : $"call {RequiredLabel}";
        }
    }

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

internal sealed class JmpDupInstruction: JmpInstruction
{
    internal JmpDupInstruction(int bits, string jmpTo) : base(InstructionCodes.Jmp, "jmp dup", bits, jmpTo)
    {
        Size = 4;
    }
    
    internal override void BuildCode(int labelAddress, int pc)
    {
        pc += Offset;
        Code = [(uint)InstructionCodes.Jmp, V1(pc), V2(pc), (uint)InstructionCodes.Dup];
    }
}

internal sealed class RetWithPstackCorrectionInstruction: Instruction
{
    private readonly uint _correction, _opCode;
    
    internal RetWithPstackCorrectionInstruction(int correction, uint opCode, string name) :
        base($"pstack correction + {name}")
    {
        Size = 3;
        _correction = (uint)correction;
        _opCode = opCode;
    }
    
    internal override void BuildCode(int labelAddress, int pc)
    {
        Code = [(uint)InstructionCodes.UpdatePstackPointer, _correction, _opCode];
    }
}

internal sealed class RetnWithPstackCorrectionInstruction: Instruction
{
    private readonly uint _correction, _n;
    
    internal RetnWithPstackCorrectionInstruction(int correction, uint n) : base($"pstack correction + retn {n}")
    {
        Size = 4;
        _correction = (uint)correction;
        _n = n;
    }
    
    internal override void BuildCode(int labelAddress, int pc)
    {
        Code = [(uint)InstructionCodes.UpdatePstackPointer, _correction, (uint)InstructionCodes.Retn, _n];
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

internal sealed class Opcode2Instruction: Instruction
{
    private readonly uint _opCode, _paramater;
    
    internal Opcode2Instruction(uint opCode, uint parameter, string name) : base(name)
    {
        _opCode = opCode;
        _paramater = parameter;
        Size = 2;
    }
    
    internal override void BuildCode(int labelAddress, int pc)
    {
        Code = [_opCode,_paramater];
    }
}

internal sealed class LoopInstruction: JmpInstruction
{
    internal LoopInstruction(int bits, string jmpTo) : base(InstructionCodes.Br, "loop (1 +loop)", bits, jmpTo)
    {
        Size = 6;
    }
    
    internal override void BuildCode(int labelAddress, int pc)
    {
        pc += Offset;
        Code = [(uint)InstructionCodes.Push, 1, 0, (uint)InstructionCodes.Loop, V1(pc), V2(pc)];
    }
}

internal sealed class PLoopInstruction: JmpInstruction
{
    internal PLoopInstruction(int bits, string jmpTo) : base(InstructionCodes.Br, "loop (1 +loop)", bits, jmpTo)
    {
        Size = 3;
    }
    
    internal override void BuildCode(int labelAddress, int pc)
    {
        pc += Offset;
        Code = [(uint)InstructionCodes.Loop, V1(pc), V2(pc)];
    }
}
