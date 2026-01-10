using GenericAssembler;

namespace Tiny16Assembler.V7Instructions;

internal sealed class JalInstruction : Instruction
{
    private readonly uint _registerNo;
    
    internal JalInstruction(string line, string file, int lineNo, uint registerNo, string label): base(line, file, lineNo)
    {
        _registerNo = registerNo;
        RequiredLabel = label;
        Size = 4;
    }
    
    public override uint[] BuildCode(uint labelAddress, uint pc)
    {
        return [InstructionCodes.Jal, _registerNo, labelAddress & 0xFF, labelAddress >> 8];
    }
}

internal sealed class JalInstructionCreator() : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        if (parameters.Count != 3 || parameters[0].Type != TokenType.Name || parameters[1].Type != TokenType.Symbol ||
            parameters[1].StringValue != "," || parameters[2].Type != TokenType.Name ||
            !GetRegisterNumber(compiler, parameters[0].StringValue, out var registerNo))
            throw new InstructionException("register name and label name expected");
        return new JalInstruction(line, file, lineNo, registerNo, parameters[2].StringValue);
    }
}