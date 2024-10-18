namespace Tiny16Assembler.V3Instructions;

using GenericAssembler;

internal sealed class LoadImmediateInstruction : Instruction
{
    private readonly uint _regNo;
    private readonly uint _value;
    
    internal LoadImmediateInstruction(string line, string file, int lineNo, uint regNo, uint value): base(line, file, lineNo)
    {
        _regNo = regNo;
        _value = value;
        Size = 2;
    }
    
    public override uint[] BuildCode(uint labelAddress, uint pc)
    {
        var li = (InstructionCodes.Li << 7) | (InstructionCodes.OpcodeForOpcode12Commands << 4) | (_regNo << 2);
        return [li, _value];
    }
}


public class LoadImmediateInstructionCreator: InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        if (parameters.Count < 3 || parameters[0].Type != TokenType.Name || !parameters[1].IsChar(',') 
            || !InstructionsHelper.GetRegisterNumber(parameters[0].StringValue, out var registerNumber))
            throw new InstructionException("register name and immediate are expected");
        var start = 2;
        var value = compiler.CalculateExpression(parameters, ref start);
        return new LoadImmediateInstruction(line, file, lineNo, registerNumber, (uint)value & 0xFFFF);
    }
}
