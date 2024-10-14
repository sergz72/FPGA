using GenericAssembler;

namespace Tiny16Assembler.V2Instructions;

internal sealed class LoadAddressInstruction : Instruction
{
    private readonly uint _regNo;
    
    internal LoadAddressInstruction(string line, string file, int lineNo, uint regNo, string labelName): base(line, file, lineNo)
    {
        _regNo = regNo;
        RequiredLabel = labelName;
    }
    
    public override uint[] BuildCode(uint labelAddress, uint pc)
    {
        //return [InstructionCodes.MovImmediate | (_regNo << 8) | (labelAddress << 16)];
        throw new NotImplementedException();
    }
}


public class LoadAddressInstructionCreator: InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        if (parameters.Count != 3 || parameters[0].Type != TokenType.Name || parameters[2].Type != TokenType.Name ||
            !parameters[1].IsChar(',') || !GetRegisterNumber(compiler, parameters[0].StringValue, out var regNo))
            throw new InstructionException("register name and label name expected");
        return new LoadAddressInstruction(line, file, lineNo, regNo, parameters[2].StringValue);
    }
}