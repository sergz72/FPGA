using GenericAssembler;

namespace Tiny16Assembler.Instructions;

internal sealed class PushfInstruction : Instruction
{
    private readonly uint _regNo;
    
    internal PushfInstruction(string line, uint regNo): base(line)
    {
        _regNo = regNo;
    }
    
    public override uint[] BuildCode(uint labelAddress)
    {
        //return [InstructionCodes.Loadf | (_regNo << 8)];
        throw new NotImplementedException();
    }
}

internal sealed class PushfInstructionCreator : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, List<Token> parameters)
    {
        if (parameters.Count == 0 || parameters[0].Type != TokenType.Name)
            throw new InstructionException("register name expected");
        if (!GetRegisterNumber(compiler, parameters[0].StringValue, out var regNo))
            throw new InstructionException("register name expected");
        return new PushfInstruction(line, regNo);
    }
}

internal sealed class PopfInstruction : Instruction
{
    private readonly uint _regNo;
    
    internal PopfInstruction(string line, uint regNo): base(line)
    {
        _regNo = regNo;
    }
    
    public override uint[] BuildCode(uint labelAddress)
    {
        //return [InstructionCodes.Loadf | (_regNo << 8)];
        throw new NotImplementedException();
    }
}

internal sealed class PopfInstructionCreator : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, List<Token> parameters)
    {
        if (parameters.Count == 0 || parameters[0].Type != TokenType.Name)
            throw new InstructionException("register name expected");
        if (!GetRegisterNumber(compiler, parameters[0].StringValue, out var regNo))
            throw new InstructionException("register name expected");
        return new PushfInstruction(line, regNo);
    }
}
