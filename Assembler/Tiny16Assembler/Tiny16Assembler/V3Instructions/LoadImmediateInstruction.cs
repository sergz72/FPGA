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
        var hiByte = _value >> 8;
        var parameter2 = (_value >> 6) & 3;
        var lui = (InstructionCodes.Lui << 4) | (_regNo << 2) | (hiByte << 8) | parameter2;
        var adi = (InstructionCodes.Adi << 4) | (_regNo << 2) | ((_value & 0x3f) << 8);
        return [lui, adi];
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
