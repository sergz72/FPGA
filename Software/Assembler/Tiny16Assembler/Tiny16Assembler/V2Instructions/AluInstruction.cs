using GenericAssembler;

namespace Tiny16Assembler.V2Instructions;

internal sealed class AluInstruction: Instruction
{
    internal AluInstruction(string line, string file, int lineNo, uint opcode) : base(line, file, lineNo)
    {
    }

    public override uint[] BuildCode(uint labelAddress, uint pc)
    {
        throw new NotImplementedException();
    }
}

internal sealed class AluInstructionCreator : InstructionCreator
{
    internal AluInstructionCreator(uint opId)
    {
        
    }
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        throw new NotImplementedException();
    }
}
