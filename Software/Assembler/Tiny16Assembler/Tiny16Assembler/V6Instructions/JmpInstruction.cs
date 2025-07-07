using GenericAssembler;

namespace Tiny16Assembler.V6Instructions;

internal sealed class JmpInstruction : Instruction
{
    private readonly uint _opCode;
    internal JmpInstruction(string line, string file, int lineNo, uint opCode, string label): base(line, file, lineNo)
    {
        _opCode = opCode;
        RequiredLabel = label;
    }
    
    public override uint[] BuildCode(uint labelAddress, uint pc)
    {
        var offset = (int)labelAddress - (int)pc;
        if (offset is > 4095 or < -4096)
        {
            string name = _opCode == InstructionCodes.Jmp ? "jmp" : "call";
            throw new InstructionException($"{File}:{LineNo}: {name} offset is out of range");
        }
        var o = (uint)offset & 0x1FFF;
        return [(_opCode << 13) | o];
    }
}

internal sealed class JmpInstructionCreator(uint opCode) : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        if (parameters.Count != 1 || parameters[0].Type != TokenType.Name)
            throw new InstructionException("label name expected");
        return new JmpInstruction(line, file, lineNo, opCode, parameters[0].StringValue);
    }
}
