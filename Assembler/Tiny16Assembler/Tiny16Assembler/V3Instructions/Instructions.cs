using GenericAssembler;

namespace Tiny16Assembler.V3Instructions;

internal static class Conditions
{
    internal const uint None = 8;
    internal const uint C = 4;
    internal const uint Z = 2;
    internal const uint MI = 1; // N
    internal const uint NC = 4 + 8;
    internal const uint NZ = 2 + 8;
    internal const uint PL = 1 + 8; // not N
    internal const uint GT = 4 + 2 + 8; // not C & not Z
    internal const uint LE = 4 + 2; // C | Z
}

internal static class InstructionCodes
{
    internal const uint OpcodeForOpcode12Commands = 5;
    internal const uint Hlt = 0;
    internal const uint Nop = 0xFF;
    internal const uint Wfi = 1;
    internal const uint Reti = 2;
    internal const uint Shr = 3;
    internal const uint Shl = 4;
    internal const uint Mv = 5;
    internal const uint Add = 6;
    internal const uint Sub = 7;
    internal const uint And = 8;
    internal const uint Or = 9;
    internal const uint Xor = 10;
    internal const uint Test = 11;
    internal const uint Cmp = 12;
    internal const uint JalReg = 13;

    internal const uint Jmp = 0;
    internal const uint Br = 1;
    internal const uint Lui = 2;
    internal const uint Sw = 3;
    internal const uint Lw = 4;
    internal const uint Loadpc = 6;
    internal const uint Jal = 7;
    
    internal const uint Adi = 8;
    internal const uint Andi = 9;
    internal const uint Ori = 10;
    internal const uint Xori = 11;
    internal const uint Testi = 12;
    internal const uint Cmpi = 13;
}

internal sealed class OpCodeInstruction(string line, string file, int lineNo, uint hiByte, uint opCode, uint parameter1, uint parameter2) :
    Instruction(line, file, lineNo)
{
    public override uint[] BuildCode(uint labelAddress, uint pc)
    {
        return [(hiByte << 8) | (opCode << 4) | (parameter1 << 2) | parameter2];
    }
}

internal sealed class OpCodeInstructionCreator(uint opCode, uint hiByte) : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        if (parameters.Count != 0)
            throw new InstructionException("unexpected instruction parameters");
        return new OpCodeInstruction(line, file, lineNo, hiByte, opCode, 0, 0);
    }
}

internal static class InstructionsHelper
{
    internal static bool GetRegisterNumber(string name, out uint registerNumber)
    {
        uint? regNo = name switch
        {
            "A" => 0,
            "W" => 1,
            "X" => 2,
            "SP" => 3,
            _ => null
        };
        registerNumber = regNo ?? 0;
        return regNo.HasValue;
    }
    
    internal static void ValidateOffset10(int offset)
    {
        if (offset is > 511 or < -512)
            throw new InstructionException($"invalid immediate or offset {offset}");
    }

    internal static void ValidateOffset10u(int offset)
    {
        if (offset is > 1023 or < 0)
            throw new InstructionException($"invalid immediate or offset {offset}");
    }
    
    internal static uint GetRegisterNumberWithOffset(ICompiler compiler, List<Token> parameters,
                                                    ref int start, out int offset)
    {
        var token = compiler.GetNextToken(parameters, ref start);
        switch (token.Type)
        {
            case TokenType.Number:
                offset = token.IntValue;
                break;
            case TokenType.Name:
                var address = compiler.FindLabel(token.StringValue);
                if (address != null)
                    offset = (int)address;
                else
                    offset = compiler.FindConstantValue(token.StringValue);
                break;
            case TokenType.Symbol:
                if (token.StringValue != "-")
                    throw new InstructionException("number or name expected");
                token = compiler.GetNextToken(parameters, ref start);
                if (token.Type != TokenType.Number)
                    throw new InstructionException("number expected");
                offset = -token.IntValue;
                break;
            default:
                throw new InstructionException("number or name expected");
        }
        ValidateOffset10(offset);
        if (!compiler.GetNextToken(parameters, ref start).IsChar('('))
            throw new InstructionException("( expected");
        token = compiler.GetNextToken(parameters, ref start);
        if (token is { Type: TokenType.Number, IntValue: 0 })
            return 0;
        if (token.Type != TokenType.Name || !GetRegisterNumber(token.StringValue, out var registerNumber))
            throw new InstructionException("register name expected");
        if (!compiler.GetNextToken(parameters, ref start).IsChar(')'))
            throw new InstructionException(") expected");
        return registerNumber;
    }
}
