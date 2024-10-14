using GenericAssembler;

namespace Tiny16Assembler.V3Instructions;

internal sealed class LoadStoreInstruction(string line, string file, int lineNo, uint opCode, uint regNo, uint offset) :
    Instruction(line, file, lineNo)
{
    public override uint[] BuildCode(uint labelAddress, uint pc)
    {
        throw new NotImplementedException();
    }
}

internal sealed class LoadStoreInstructionCreator(uint opCode) : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        throw new NotImplementedException();
    }
}
