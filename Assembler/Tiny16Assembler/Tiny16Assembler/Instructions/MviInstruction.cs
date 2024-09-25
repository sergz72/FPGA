using GenericAssembler;

namespace Tiny16Assembler.Instructions;

internal sealed class MviInstruction: Instruction
{
    private readonly uint _opcode, _regNo, _value;
    
    internal MviInstruction(string line, uint opcode, uint regNo, uint value): base(line)
    {
        _opcode = opcode;
        _regNo = regNo;
        _value = value;
    }

    public override uint[] BuildCode(uint labelAddress)
    {
        return [(_opcode << 10) | (_value << 4) | _regNo];
    }
}

internal sealed class MviInstructionCreator : InstructionCreator
{
    private readonly uint _opcode;
    internal MviInstructionCreator(uint opcode)
    {
        _opcode = opcode;
    }

    public override Instruction Create(ICompiler compiler, string line, List<Token> parameters)
    {
        throw new NotImplementedException();
    }
}
