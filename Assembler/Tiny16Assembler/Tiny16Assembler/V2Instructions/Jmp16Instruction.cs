using GenericAssembler;

namespace Tiny16Assembler.V2Instructions;

internal sealed class Jmp16Instruction: Instruction
{
    internal Jmp16Instruction(string line, string file, int lineNo, uint opcode, uint condition) : base(line, file, lineNo)
    {
    }

    public override uint[] BuildCode(uint labelAddress, uint pc)
    {
        throw new NotImplementedException();
    }
}

internal sealed class Jmp16InstructionCreator : InstructionCreator
{
    internal Jmp16InstructionCreator(uint opcode, uint condition)
    {
        
    }
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        throw new NotImplementedException();
    }
}
