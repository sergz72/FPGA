using GenericAssembler;

namespace Tiny16Assembler.V2Instructions;

internal sealed class MovInstruction: Instruction
{
    private readonly uint _opcode, _regNo, _value, _flags;
    
    internal MovInstruction(string line, string file, int lineNo, uint opcode, uint regNo, uint value, uint flags):
        base(line, file, lineNo)
    {
        _opcode = opcode;
        _regNo = regNo;
        _value = value;
        _flags = flags;
    }

    public override uint[] BuildCode(uint labelAddress, uint pc)
    {
        return [(_opcode << 10) | (_flags << 8) | (_value << 4) | _regNo];
    }
}

internal sealed class MovInstructionCreator : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        throw new NotImplementedException();
    }
}
