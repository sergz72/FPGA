using GenericAssembler;

namespace Cpu16LiteAssembler.Instructions;

internal sealed class MovInstruction : Instruction
{
    private readonly uint _type, _regNo, _value2, _adder;
    
    internal MovInstruction(string line, uint type, uint regNo, uint value2, uint adder): base(line)
    {
        _type = type;
        _regNo = regNo;
        _value2 = value2;
        _adder = adder;
    }
    
    public override uint BuildCode(ushort labelAddress)
    {
        if (_type is InstructionCodes.MovImmediate or InstructionCodes.MovRpImmediate or
            InstructionCodes.MovRpImmediateRpDec or InstructionCodes.MovRpImmediateRpInc)
            return _type | (_regNo << 8) | (_value2 << 16);
        else
            return _type | (_regNo << 8) | (_value2 << 16) | (_adder << 24);
    }
}

internal sealed class MovInstructionCreator : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, List<Token> parameters)
    {
        var idx = 0;
        if (parameters.Count >= 4 && ParseRp(parameters, ref idx, out var increment, out var decrement))
            return CreateIndirect1(compiler, line, parameters[idx..], increment, decrement);
        if (parameters.Count < 3 || parameters[0].Type != TokenType.Name)
            throw new InstructionException("register name and register/immediate expected");
        if (!parameters[1].IsChar(','))
            throw new InstructionException(", expected");
        if (parameters[0].StringValue == "rp")
        {
            var rp = compiler.CalculateExpression(parameters[2..]);
            if (rp is < 0 or > 255)
                throw new InstructionException("rp value is out of range");
            return new MovInstruction(line, InstructionCodes.LoadRp, 0, 0, (uint)rp);
        }
        if (!GetRegisterNumber(compiler, parameters[0].StringValue, out var regNo))
            throw new InstructionException("register name expected");
        idx = 2;
        if (ParseRp(parameters, ref idx, out increment, out decrement))
            return CreateIndirect2(compiler, line, regNo, parameters, idx, increment, decrement);
        if (GetRegisterNumber(compiler, parameters[2].StringValue, out var regNo2))
        {
            var adder = 0;
            if (parameters.Count > 3)
            {
                if (parameters.Count == 4)
                    throw new InstructionException("invalid number of parameters");
                if (!parameters[3].IsChar('+'))
                    throw new InstructionException("+ expected");
                adder = compiler.CalculateExpression(parameters[4..]);
            }

            return new MovInstruction(line, InstructionCodes.MovReg, regNo, regNo2, (uint)adder);
        }

        var value2 = compiler.CalculateExpression(parameters[2..]);
        return new MovInstruction(line, InstructionCodes.MovImmediate, regNo, (uint)value2, 0);
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

        decrement = parameters[idx].IsChar("--");
        if (decrement)
            idx++;
        if (parameters[idx].Type != TokenType.Name || parameters[idx].StringValue != "rp")
            throw new InstructionException("rp expected");
        idx++;
        increment = parameters[idx].IsChar("++");
        if (increment)
            idx++;
        return true;
    }

    private Instruction CreateIndirect2(ICompiler compiler, string line, uint regNo, List<Token> parameters, int idx,
        bool increment, bool decrement)
    {
        var adder = 0;
        if (parameters.Count > idx)
        {
            if (!parameters[idx++].IsChar('+'))
                throw new InstructionException("+ expected");
            adder = compiler.CalculateExpression(parameters[idx..]);
        }
        if (increment)
            return new MovInstruction(line, InstructionCodes.MovRegisterRpRpInc, regNo, (uint)adder, 0xFE);
        if (decrement)
            return new MovInstruction(line, InstructionCodes.MovRegisterRpRpDec, regNo, (uint)adder, 0xFF);
        return new MovInstruction(line, InstructionCodes.MovRegisterRp, regNo, (uint)adder, 0xFE);
    }
    
    private Instruction CreateIndirect1(ICompiler compiler, string line, List<Token> parameters,
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
                adder = compiler.CalculateExpression(parameters[3..]);
            }

            if (increment)
                return new MovInstruction(line, InstructionCodes.MovRpRegisterRpInc, 0, regNo, (uint)adder);
            if (decrement)
                return new MovInstruction(line, InstructionCodes.MovRpRegisterRpDec, 0, regNo, (uint)adder);
            return new MovInstruction(line, InstructionCodes.MovRpRegister, 0, regNo, (uint)adder);
        }

        var value2 = compiler.CalculateExpression(parameters[1..]);
        if (increment)
            return new MovInstruction(line, InstructionCodes.MovRpImmediateRpInc, 0, (uint)value2, 0);
        if (decrement)
            return new MovInstruction(line, InstructionCodes.MovRpImmediateRpDec, 0, (uint)value2, 0);
        return new MovInstruction(line, InstructionCodes.MovRpImmediate, 0, (uint)value2, 0);
    }
}
