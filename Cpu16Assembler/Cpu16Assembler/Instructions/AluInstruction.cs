namespace Cpu16Assembler.Instructions;

internal sealed class AluRegisterInstruction : Instruction
{
    private readonly uint _aluOperation, _type, _regNo, _regNo2, _regNo3;
    
    internal AluRegisterInstruction(string line, uint type, uint aluOperation, uint regNo, uint regNo2, uint regNo3): base(line)
    {
        _aluOperation = aluOperation;
        _type = type;
        _regNo = regNo;
        _regNo2 = regNo2;
        _regNo3 = regNo3;
    }
    
    internal override uint BuildCode(ushort labelAddress)
    {
        return _aluOperation | _type | (_regNo << 8) | (_regNo2 << 16) | (_regNo3 << 24);
    }
}

internal sealed class AluInstructionCreator(uint aluOperation) : InstructionCreator
{
    internal override Instruction Create(ICompiler compiler, string line, List<Token> parameters)
    {
        if (aluOperation is AluOperations.Test or AluOperations.Cmp)
            return CreateTest(compiler, line, parameters);
        int start = 0;
        if (parameters.Count < 3 ||
            !GetRegisterNumberWithIoFlag(parameters, ref start, out var regNo, out var io))
            throw new InstructionException("register name expected");
        if (start == parameters.Count || !parameters[start].IsChar(','))
            throw new InstructionException(", expected");
        start++;
        if (start == parameters.Count)
            throw new InstructionException("register or immediate expected");
        if (parameters[start].Type == TokenType.Name &&
            GetRegisterNumber(parameters[start].StringValue, out var regNo2))
        {
            start++;
            if (parameters.Count < start + 2 || !parameters[start].IsChar(','))
                throw new InstructionException(", expected");
            start++;
            if (!GetRegisterNumberWithIoFlag(parameters, ref start, out var regNo3, out var io2))
                throw new InstructionException("register3 name expected");
            if (io && io2)
                throw new InstructionException("illegal io operation");
            if (!io && !io2)
                // register-register
                return new AluRegisterInstruction(line, 0x60, aluOperation, regNo, regNo2, regNo3);
            else if (io)
                // register-io
                return new AluRegisterInstruction(line, 0xB0, aluOperation, regNo, regNo2, regNo3);
            else
                // io-register
                return new AluRegisterInstruction(line, 0xA0, aluOperation, regNo, regNo2, regNo3);
        }
        var v = (uint)compiler.CalculateExpression(parameters[2..]);
        return new AluImmediateInstruction(line, aluOperation, regNo, v);
    }

    private Instruction CreateTest(ICompiler compiler, string line, List<Token> parameters)
    {
        throw new NotImplementedException();
    }
}
