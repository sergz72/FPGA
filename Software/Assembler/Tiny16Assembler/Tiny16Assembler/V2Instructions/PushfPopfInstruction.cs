using GenericAssembler;

namespace Tiny16Assembler.V2Instructions;

internal sealed class PushfInstruction : Instruction
{
    private readonly uint _regNo;
    
    internal PushfInstruction(string line, string file, int lineNo, uint regNo): base(line, file, lineNo)
    {
        _regNo = regNo;
    }
    
    public override uint[] BuildCode(uint labelAddress, uint pc)
    {
        //return [InstructionCodes.Loadf | (_regNo << 8)];
        throw new NotImplementedException();
    }
}

internal sealed class PushfInstructionCreator : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        if (parameters.Count == 0 || parameters[0].Type != TokenType.Name)
            throw new InstructionException("register name expected");
        if (!GetRegisterNumber(compiler, parameters[0].StringValue, out var regNo))
            throw new InstructionException("register name expected");
        return new PushfInstruction(line, file, lineNo, regNo);
    }
}

internal sealed class PopfInstruction : Instruction
{
    private readonly uint _regNo;
    
    internal PopfInstruction(string line, string file, int lineNo, uint regNo): base(line, file, lineNo)
    {
        _regNo = regNo;
    }
    
    public override uint[] BuildCode(uint labelAddress, uint pc)
    {
        //return [InstructionCodes.Loadf | (_regNo << 8)];
        throw new NotImplementedException();
    }
}

internal sealed class PopfInstructionCreator : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        if (parameters.Count == 0 || parameters[0].Type != TokenType.Name)
            throw new InstructionException("register name expected");
        if (!GetRegisterNumber(compiler, parameters[0].StringValue, out var regNo))
            throw new InstructionException("register name expected");
        return new PushfInstruction(line, file, lineNo, regNo);
    }
}
