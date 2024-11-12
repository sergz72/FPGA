using GenericAssembler;

namespace Cpu16LiteAssembler.Instructions;

internal sealed class MovInstruction : Instruction
{
    private readonly uint _type, _regNo, _value2, _adder;
    
    internal MovInstruction(string line, string file, int lineNo, uint type, uint regNo, uint value2, uint adder):
        base(line, file, lineNo)
    {
        _type = type;
        _regNo = regNo;
        _value2 = value2;
        _adder = adder;
    }
    
    public override uint[] BuildCode(uint labelAddress, uint pc)
    {
        if (_type is InstructionCodes.MovImmediate or InstructionCodes.MovRpImmediate or
            InstructionCodes.MovRpImmediateRpDec or InstructionCodes.MovRpImmediateRpInc)
            return [_type | (_regNo << 8) | (_value2 << 16)];
        else
            return [_type | (_regNo << 8) | (_value2 << 16) | (_adder << 24)];
    }
}

internal sealed class MovInstructionCreator : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        var idx = 0;
        if (parameters.Count >= 4 && ParseRp(parameters, ref idx, out var increment, out var decrement))
            return CreateIndirect1(compiler, line, file, lineNo, parameters[idx..], increment, decrement);
        if (parameters.Count < 3 || parameters[0].Type != TokenType.Name)
            throw new InstructionException("register name and register/immediate expected");
        if (!parameters[1].IsChar(','))
            throw new InstructionException(", expected");
        if (parameters[0].StringValue == "rp")
        {
            var start = 2;
            var rp = compiler.CalculateExpression(parameters, ref start);
            if (rp is < 0 or > 255)
                throw new InstructionException("rp value is out of range");
            return new MovInstruction(line, file, lineNo, InstructionCodes.LoadRp, 0, 0, (uint)rp);
        }
        if (!GetRegisterNumber(compiler, parameters[0].StringValue, out var regNo))
            throw new InstructionException("register name expected");
        idx = 2;
        if (ParseRp(parameters, ref idx, out increment, out decrement))
            return CreateIndirect2(compiler, line, file, lineNo, regNo, parameters, idx, increment, decrement);
        if (GetRegisterNumber(compiler, parameters[2].StringValue, out var regNo2))
        {
            var adder = 0;
            if (parameters.Count > 3)
            {
                if (parameters.Count == 4)
                    throw new InstructionException("invalid number of parameters");
                if (!parameters[3].IsChar('+'))
                    throw new InstructionException("+ expected");
                var start = 4;
                adder = (int)compiler.CalculateExpression(parameters, ref start);
            }

            return new MovInstruction(line, file, lineNo, InstructionCodes.MovReg, regNo, regNo2, (uint)adder);
        }

        var start2 = 2;
        var value2 = compiler.CalculateExpression(parameters, ref start2);
        return new MovInstruction(line, file, lineNo, InstructionCodes.MovImmediate, regNo, (uint)value2, 0);
    }

    public static bool ParseRp(List<Token> parameters, ref int idx, out bool increment, out bool decrement)
    {
        if (!parameters[idx].IsChar('@'))
        {
            increment = false;
            decrement = false;
            return false;
        }
        
        idx++;

        if (idx == parameters.Count)
            throw new InstructionException("rp expected");
        
        decrement = parameters[idx].IsChar("--");
        if (decrement)
            idx++;

        if (idx == parameters.Count)
            throw new InstructionException("rp expected");

        if (parameters[idx].Type != TokenType.Name || parameters[idx].StringValue != "rp")
            throw new InstructionException("rp expected");
        idx++;

        if (idx == parameters.Count)
        {
            increment = false;
            return true;
        }

        increment = parameters[idx].IsChar("++");
        if (increment)
            idx++;
        
        return true;
    }

    private Instruction CreateIndirect2(ICompiler compiler, string line, string file, int lineNo, uint regNo, List<Token> parameters, int idx,
        bool increment, bool decrement)
    {
        var adder = 0;
        if (parameters.Count > idx)
        {
            if (!parameters[idx++].IsChar('+'))
                throw new InstructionException("+ expected");
            adder = (int)compiler.CalculateExpression(parameters, ref idx);
        }
        if (increment)
            return new MovInstruction(line, file, lineNo, InstructionCodes.MovRegisterRpRpInc, regNo, (uint)adder, 0);
        if (decrement)
            return new MovInstruction(line, file, lineNo, InstructionCodes.MovRegisterRpRpDec, regNo, (uint)adder, 0);
        return new MovInstruction(line, file, lineNo, InstructionCodes.MovRegisterRp, regNo, (uint)adder, 0);
    }
    
    private Instruction CreateIndirect1(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters,
        bool increment, bool decrement)
    {
        if (parameters.Count < 2 || !parameters[0].IsChar(','))
            throw new InstructionException(", expected");

        if (GetRegisterNumber(compiler, parameters[1].StringValue, out var regNo))
        {
            var adder = 0;
            if (parameters.Count > 2)
            {
                if (parameters.Count == 3)
                    throw new InstructionException("invalid number of parameters");
                if (!parameters[2].IsChar('+'))
                    throw new InstructionException("+ expected");
                var start = 3;
                adder = (int)compiler.CalculateExpression(parameters, ref start);
            }

            if (increment)
                return new MovInstruction(line, file, lineNo, InstructionCodes.MovRpRegisterRpInc, regNo, (uint)adder, 0);
            if (decrement)
                return new MovInstruction(line, file, lineNo, InstructionCodes.MovRpRegisterRpDec, regNo, (uint)adder, 0);
            return new MovInstruction(line, file, lineNo, InstructionCodes.MovRpRegister, regNo, (uint)adder, 0);
        }

        var start1 = 1;
        var value2 = compiler.CalculateExpression(parameters, ref start1);
        if (increment)
            return new MovInstruction(line, file, lineNo, InstructionCodes.MovRpImmediateRpInc, 0, (uint)value2, 0);
        if (decrement)
            return new MovInstruction(line, file, lineNo, InstructionCodes.MovRpImmediateRpDec, 0, (uint)value2, 0);
        return new MovInstruction(line, file, lineNo, InstructionCodes.MovRpImmediate, 0, (uint)value2, 0);
    }
}
