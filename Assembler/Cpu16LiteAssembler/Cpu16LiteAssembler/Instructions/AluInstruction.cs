using GenericAssembler;

namespace Cpu16LiteAssembler.Instructions;

internal sealed class AluRegisterInstruction : Instruction
{
    private readonly uint _aluOperation, _type, _regNo, _regNo2, _regNo3;
    
    internal AluRegisterInstruction(string line, string file, int lineNo, uint type, uint aluOperation, uint regNo,
                                    uint regNo2, uint regNo3): base(line, file, lineNo)
    {
        _aluOperation = aluOperation;
        _type = type;
        _regNo = regNo;
        _regNo2 = regNo2;
        _regNo3 = regNo3;
    }
    
    public override uint[] BuildCode(uint labelAddress, uint pc)
    {
        return [_aluOperation | _type | (_regNo << 8) | (_regNo2 << 16) | (_regNo3 << 24)];
    }
}

internal sealed class AluInstructionCreator(uint aluOperation) : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        if (aluOperation is AluOperations.Test or AluOperations.Cmp)
            return Create2Op(compiler, line, file, lineNo, parameters);
        if (aluOperation is AluOperations.Neg or AluOperations.Rlc or AluOperations.Rrc or AluOperations.Shlc or AluOperations.Shrc)
            return Create2OpRegReg(compiler, line, file, lineNo, parameters);
        if (aluOperation is AluOperations.Setf)
            return Create1Op(compiler, line, file, lineNo, parameters);
        if (parameters.Count < 3 || parameters[0].Type != TokenType.Name || !parameters[1].IsChar(','))
            throw new InstructionException("syntax error");
        
        if (!GetRegisterNumber(compiler, parameters[0].StringValue, out var regNo))
            throw new InstructionException("invalid register 1 name");
        
        if (parameters[2].Type != TokenType.Name || !GetRegisterNumber(compiler, parameters[2].StringValue, out var regNo2))
        {
            var start = 2;
            var v = (uint)compiler.CalculateExpression(parameters, ref start);
            return new AluImmediateInstruction(line, file, lineNo, aluOperation, regNo, v);
        }
        
        if (parameters.Count != 5 || parameters[4].Type != TokenType.Name || !parameters[3].IsChar(','))
            throw new InstructionException("syntax error");
            
        if (!GetRegisterNumber(compiler, parameters[4].StringValue, out var regNo3))
            throw new InstructionException("invalid register 3 name");

        return new AluRegisterInstruction(line, file, lineNo, 0x60, aluOperation, regNo, regNo2, regNo3);
    }

    private Instruction Create1Op(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        if (parameters.Count != 1 || parameters[0].Type != TokenType.Name ||
            !GetRegisterNumber(compiler, parameters[0].StringValue, out var regNo))
            throw new InstructionException("register name expected");
        // register-register
        return new AluRegisterInstruction(line, file, lineNo, 0x60, aluOperation, regNo, 0, 0);
    }

    private Instruction Create2OpRegReg(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        if (parameters.Count != 3 || parameters[0].Type != TokenType.Name || !parameters[1].IsChar(',') ||
            !GetRegisterNumber(compiler, parameters[0].StringValue, out var regNo) ||
            !GetRegisterNumber(compiler, parameters[2].StringValue, out var regNo2))
            throw new InstructionException("syntax error");
        // register-register
        return new AluRegisterInstruction(line, file, lineNo, 0x60, aluOperation, regNo, regNo2, 0);
    }
    
    private Instruction Create2Op(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        if (parameters.Count < 3 || parameters[0].Type != TokenType.Name || !parameters[1].IsChar(',') ||
            !GetRegisterNumber(compiler, parameters[0].StringValue, out var regNo))
            throw new InstructionException("syntax error");
        if (parameters[2].Type != TokenType.Name || !GetRegisterNumber(compiler, parameters[2].StringValue, out var regNo2))
        {
            // immediate and register
            var start = 2;
            var v = (uint)compiler.CalculateExpression(parameters, ref start);
            return new AluImmediateInstruction(line, file, lineNo, aluOperation, regNo, v);
        }
        // register-register
        return new AluRegisterInstruction(line, file, lineNo, 0x60, aluOperation, 0, regNo, regNo2);
    }
}
