using GenericAssembler;

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
    
    public override uint BuildCode(ushort labelAddress)
    {
        return _aluOperation | _type | (_regNo << 8) | (_regNo2 << 16) | (_regNo3 << 24);
    }
}

internal sealed class AluInstructionCreator(uint aluOperation) : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, List<Token> parameters)
    {
        if (aluOperation is AluOperations.Test or AluOperations.Cmp or AluOperations.Setf)
            return CreateTest(compiler, line, parameters);
        if (aluOperation == AluOperations.Neg)
            return CreateNeg(compiler, line, parameters);
        if (parameters.Count < 3 || parameters[0].Type != TokenType.Name || !parameters[1].IsChar(','))
            throw new InstructionException("syntax error");
        
        if (!GetRegisterNumber(parameters[0].StringValue, out var regNo))
            throw new InstructionException("invalid register 1 name");
        
        if (parameters[2].Type != TokenType.Name || !GetRegisterNumber(parameters[2].StringValue, out var regNo2))
        {
            var v = (uint)compiler.CalculateExpression(parameters[2..]);
            return new AluImmediateInstruction(line, aluOperation, regNo, v);
        }
        
        if (parameters.Count != 5 || parameters[4].Type != TokenType.Name || !parameters[3].IsChar(','))
            throw new InstructionException("syntax error");
            
        if (!GetRegisterNumber(parameters[2].StringValue, out var regNo3))
            throw new InstructionException("invalid register 3 name");

        return new AluRegisterInstruction(line, 0x60, aluOperation, regNo, regNo2, regNo3);
    }

    private Instruction CreateTest(ICompiler _, string line, List<Token> parameters)
    {
        if (parameters.Count != 1 || parameters[0].Type != TokenType.Name ||
            !GetRegisterNumber(parameters[0].StringValue, out var regNo))
            throw new InstructionException("register name expected");
        // register-register
        return new AluRegisterInstruction(line, 0x60, aluOperation, regNo, 0, 0);
    }

    private Instruction CreateNeg(ICompiler _, string line, List<Token> parameters)
    {
        if (parameters.Count != 3 || parameters[0].Type != TokenType.Name || parameters[2].Type != TokenType.Name ||
            !parameters[1].IsChar(',') ||
            !GetRegisterNumber(parameters[0].StringValue, out var regNo) || 
            !GetRegisterNumber(parameters[2].StringValue, out var regNo2))
            throw new InstructionException("syntax error");
        // register-register
        return new AluRegisterInstruction(line, 0x60, aluOperation, regNo, regNo2, 0);
    }
}
