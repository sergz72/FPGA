using GenericAssembler;

namespace Tiny16Assembler.V6Instructions;

internal sealed class ConstantsInstruction : Instruction
{
    private readonly Tiny16V6Compiler _compiler;
    internal ConstantsInstruction(string line, string file, int lineNo, Tiny16V6Compiler compiler): base(line, file, lineNo)
    {
        _compiler = compiler;
        RequiredLabel = "_constants";
    }
    
    public override uint[] BuildCode(uint labelAddress, uint pc)
    {
        return _compiler.GetConstants(pc);
    }

    public override void UpdateSize(uint labelAddress, uint pc)
    {
        Size = _compiler.BuildConstants(pc);
    }
}

internal sealed class ConstantsInstructionCreator() : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        if (parameters.Count != 0)
            throw new InstructionException("no parameters expected");
        compiler.AddLabel("_constants", "_constants");
        return new ConstantsInstruction(line, file, lineNo, (compiler as  Tiny16V6Compiler)!);
    }
}
