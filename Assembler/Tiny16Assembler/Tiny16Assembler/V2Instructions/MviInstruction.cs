using GenericAssembler;

namespace Tiny16Assembler.V2Instructions;

internal sealed class MviInstruction: Instruction
{
    private readonly uint _opcode, _regNo, _value;
    
    internal MviInstruction(string line, string file, int lineNo, uint opcode, uint regNo, uint value): base(line, file, lineNo)
    {
        _opcode = opcode;
        _regNo = regNo;
        _value = value;
    }

    public override uint[] BuildCode(uint labelAddress, uint pc)
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

    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        throw new NotImplementedException();
    }
}
