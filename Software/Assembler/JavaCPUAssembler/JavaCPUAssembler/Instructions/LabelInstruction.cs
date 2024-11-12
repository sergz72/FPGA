using System.Reflection.Emit;
using GenericAssembler;

namespace JavaCPUAssembler.Instructions;

internal sealed class Label32Instruction : Instruction
{
    private readonly uint _opCode;
    internal Label32Instruction(string line, string file, int lineNo, uint opCode, string label): base(line, file, lineNo)
    {
        _opCode = opCode;
        RequiredLabel = label;
        Size = 3;
    }
    
    public override uint[] BuildCode(uint labelAddress, uint pc)
    {
        return [_opCode << 8, labelAddress & 0xFFFF, labelAddress >> 16];
    }
}

internal sealed class Label16Instruction : Instruction
{
    private readonly uint _opCode;
    internal Label16Instruction(string line, string file, int lineNo, uint opCode, string label): base(line, file, lineNo)
    {
        _opCode = opCode;
        RequiredLabel = label;
        Size = 2;
    }
    
    public override uint[] BuildCode(uint labelAddress, uint pc)
    {
        var offset = labelAddress - pc - 1;
        return [_opCode, offset];
    }
}

internal sealed class Label32InstructionCreator(uint opCode) : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        if (parameters.Count != 1 || parameters[0].Type != TokenType.Name)
            throw new InstructionException("label name expected");
        return new Label32Instruction(line, file, lineNo, opCode, parameters[0].StringValue);
    }
}

internal sealed class Label16InstructionCreator(uint opCode, uint parameter) : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        if (parameters.Count != 1 || parameters[0].Type != TokenType.Name)
            throw new InstructionException("label name expected");
        return new Label16Instruction(line, file, lineNo, (opCode << 8) | parameter, parameters[0].StringValue);
    }
}
