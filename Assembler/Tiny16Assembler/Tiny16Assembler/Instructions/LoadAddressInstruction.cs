using GenericAssembler;

namespace Tiny16Assembler.Instructions;

internal sealed class LoadAddressInstruction : Instruction
{
    private readonly uint _regNo;
    
    internal LoadAddressInstruction(string line, uint regNo, string labelName): base(line)
    {
        _regNo = regNo;
        RequiredLabel = labelName;
    }
    
    public override uint[] BuildCode(uint labelAddress)
    {
        //return [InstructionCodes.MovImmediate | (_regNo << 8) | (labelAddress << 16)];
        throw new NotImplementedException();
    }
}


public class LoadAddressInstructionCreator: InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, List<Token> parameters)
    {
        if (parameters.Count != 3 || parameters[0].Type != TokenType.Name || parameters[2].Type != TokenType.Name ||
            !parameters[1].IsChar(',') || !GetRegisterNumber(compiler, parameters[0].StringValue, out var regNo))
            throw new InstructionException("register name and label name expected");
        return new LoadAddressInstruction(line, regNo, parameters[2].StringValue);
    }
}