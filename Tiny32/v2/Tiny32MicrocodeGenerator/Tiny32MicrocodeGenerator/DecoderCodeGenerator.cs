namespace Tiny32MicrocodeGenerator;

internal static class DecoderCodeGenerator
{
    internal enum Commands
    {
        Wfi = 0,
        Reti,
        Hlt,
        Lb,
        Lh,
        Lw,
        Lbu,
        Lhu,
        Addi,
        Slli,
        Slti,
        Sltiu,
        Xori,
        Srli,
        Srai,
        Ori,
        Andi,
        Auipc,
        Sb,
        Sh,
        Sw,
        Add,
        Sub,
        Sll,
        Slt,
        Sltu,
        Xor,
        Srl,
        Sra,
        Or,
        And,
        Lui,
        Br,
        Jalr,
        Jal,
        Mul,
        Mulh,
        Mulhsu,
        Mulhu,
        Div,
        Divu,
        Rem,
        Remu
    }
    
    private const int CodeLength = 1024;
    private const int Error = 0b1100_0010;

    internal static void GenerateCode(bool mul, bool div)
    {
        var lines = new List<string>();
        for (var i = 0; i < CodeLength; i++)
        {
            var func7 = i & 3;
            var v = (i >> 2) switch
            {
                0b00000_000 => (int)Commands.Lb,
                0b00000_001 => (int)Commands.Lh,
                0b00000_010 => (int)Commands.Lw,
                0b00000_100 => (int)Commands.Lbu,
                0b00000_101 => (int)Commands.Lhu,
                0b00010_000 => (int)Commands.Wfi,
                0b00010_001 => (int)Commands.Reti,
                0b00010_010 => (int)Commands.Hlt | 0x80,
                0b00100_000 => (int)Commands.Addi,
                0b00100_001 => func7 == 0 ? (int)Commands.Slli : Error,
                0b00100_010 => (int)Commands.Slti,
                0b00100_011 => (int)Commands.Sltiu,
                0b00100_100 => (int)Commands.Xori,
                0b00100_101 => func7 switch
                {
                    0 => (int)Commands.Srli,
                    2 => (int)Commands.Srai,
                    _ => Error
                },
                0b00100_110 => (int)Commands.Ori,
                0b00100_111 => (int)Commands.Andi,
                >= 0b00101_000 and <= 0b00101_111 => (int)Commands.Auipc,
                0b01000_000 => (int)Commands.Sb,
                0b01000_001 => (int)Commands.Sh,
                0b01000_010 => (int)Commands.Sw,
                0b01100_000 => func7 switch
                {
                    0 => (int)Commands.Add,
                    1 => mul ? (int)Commands.Mul : Error,
                    2 => (int)Commands.Sub,
                    _ => Error
                },
                0b01100_001 => func7 switch
                {
                    0 => (int)Commands.Sll,
                    1 => mul ? (int)Commands.Mulh : Error,
                    _ => Error
                },
                0b01100_010 => func7 switch
                {
                    0 => (int)Commands.Slt,
                    1 => mul ? (int)Commands.Mulhsu : Error,
                    _ => Error
                },
                0b01100_011 => func7 switch
                {
                    0 => (int)Commands.Sltu,
                    1 => mul ? (int)Commands.Mulhu : Error,
                    _ => Error
                },
                0b01100_100 => func7 switch
                {
                    0 => (int)Commands.Xor,
                    1 => div ? (int)Commands.Div : Error,
                    _ => Error
                },
                0b01100_101 => func7 switch
                {
                    0 => (int)Commands.Srl,
                    1 => div ? (int)Commands.Divu : Error,
                    2 => (int)Commands.Sra,
                    _ => Error
                },
                0b01100_110 => func7 switch
                {
                    0 => (int)Commands.Or,
                    1 => div ? (int)Commands.Rem : Error,
                    _ => Error
                },
                0b01100_111 => func7 switch
                {
                    0 => (int)Commands.And,
                    1 => div ? (int)Commands.Remu : Error,
                    _ => Error
                },
                >= 0b01101_000 and <= 0b01101_111 => (int)Commands.Lui,
                0b11000_000 => (int)Commands.Br,
                0b11000_001 => (int)Commands.Br,
                0b11000_100 => (int)Commands.Br,
                0b11000_101 => (int)Commands.Br,
                0b11000_110 => (int)Commands.Br,
                0b11000_111 => (int)Commands.Br,
                0b11001_000 => (int)Commands.Jalr,
                >= 0b11011_000 and <= 0b11011_111 => (int)Commands.Jal,
                _ => Error
            };
            
            
            lines.Add(v.ToString("X2"));
        }
        File.WriteAllLines("decoder.mem", lines);
    }
}