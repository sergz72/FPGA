using GenericAssembler;

namespace Tiny16Assembler.V2Instructions;

internal sealed class Jmp11Instruction: Instruction
{
    internal Jmp11Instruction(string line, string file, int lineNo, uint opcode) : base(line, file, lineNo)
    {
    }

    public override uint[] BuildCode(uint labelAddress, uint pc)
    {
        throw new NotImplementedException();
    }
}

internal sealed class Jmp11InstructionCreator : InstructionCreator
{
    internal Jmp11InstructionCreator(uint opcode)
    {
        
    }
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        throw new NotImplementedException();
    }
}
