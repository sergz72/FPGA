using GenericAssembler;

namespace Cpu16LiteAssembler.Instructions;

internal sealed class JmpInstruction : Instruction
{
    private readonly uint _type, _regNo, _adder;
    
    internal JmpInstruction(string line, string file, int lineNo, uint type, uint regNo, uint adder, string? label):
        base(line, file, lineNo)
    {
        _type = type;
        _regNo = regNo;
        _adder = adder;
        RequiredLabel = label;
    }
    
    public override uint[] BuildCode(uint labelAddress, uint pc)
    {
        return [_type | (_regNo << 8) | (_adder << 16) | ((uint)labelAddress << 16)];
    }
}

internal sealed class JmpInstructionCreator(uint addrCode, uint regCode) : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        if (parameters.Count == 0 || parameters[0].Type != TokenType.Name)
            throw new InstructionException("label name or register name+adder expected");
        if (GetRegisterNumber(compiler, parameters[0].StringValue, out var regNo))
        {
            uint adder = 0;
            
            if (parameters.Count > 1)
            {
                if (!parameters[1].IsChar('+'))
                    throw new InstructionException("+ expected");
                var start = 2;
                adder = (uint)compiler.CalculateExpression(parameters, ref start);
            }   
            return new JmpInstruction(line, file, lineNo, regCode, regNo, adder, null);
        }
        if (parameters.Count != 1)
            throw new InstructionException("label name expected");
        return new JmpInstruction(line, file, lineNo, addrCode, 0, 0, parameters[0].StringValue);
    }
}
