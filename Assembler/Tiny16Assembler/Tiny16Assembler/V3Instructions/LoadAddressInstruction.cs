using GenericAssembler;

namespace Tiny16Assembler.V3Instructions;

internal sealed class LoadAddressInstruction : Instruction
{
    private readonly uint _regNo;
    
    internal LoadAddressInstruction(string line, string file, int lineNo, uint regNo, string labelName): base(line, file, lineNo)
    {
        _regNo = regNo;
        RequiredLabel = labelName;
        Size = 2;
    }
    
    public override uint[] BuildCode(uint labelAddress, uint pc)
    {
        var li = (InstructionCodes.Li << 7) | (InstructionCodes.OpcodeForOpcode12Commands << 4) | (_regNo << 2);
        return [li, labelAddress];
    }
}


public class LoadAddressInstructionCreator: InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        if (parameters.Count != 3 || parameters[0].Type != TokenType.Name || parameters[2].Type != TokenType.Name ||
            !parameters[1].IsChar(',') || !InstructionsHelper.GetRegisterNumber(parameters[0].StringValue, out var registerNumber))
            throw new InstructionException("register name and label name expected");
        return new LoadAddressInstruction(line, file, lineNo, registerNumber, parameters[2].StringValue);
    }
}
