namespace Tiny32MicrocodeGenerator;

internal class MicrocodeGenerator
{
    private enum AluOp
    {
        Sl = 0,
        Sr,
        Sra,
        And,
        Or,
        Xor,
        Sltu,
        Slt,
        Add,
        Sub,
        Mul,
        Mulh,
        Mulhsu,
        Mulhu,
        Div,
        Divu,
        Rem,
        Remu
    }
    
    private const int CodeLength = 256;

    private readonly int _registersWr, _load, _store, _err, _setPc, _pcSource, _pcSourcePcPlusImm12b;
    private readonly int _pcSourcePcPlusImm20j, _pcSourceSource1RegDataPlusImm12i, _pcSourceSavedPc, _addressSource;
    private readonly int _registersWrDataSource, _registersWrDataSourceDataLoadF, _noStore;
    private readonly int _registersWrDataSourceAluOut, _inInterruptClear, _aluClk, _aluOp1Source;
    private readonly int _aluOp1SourceSource1RegData, _aluOp1SourceImm20u, _aluOp1Source4, _aluOp2Source;
    private readonly int _aluOp2SourceImm12i, _aluOp2SourceImm12iSigned, _aluOp2SourceSource2RegData;
    private readonly int _aluOp2SourceSource2RegData40, _aluOp2SourceSourcePc, _aluOp, _dataLoadSigned, _dataShift;

    internal MicrocodeGenerator()
    {
        _registersWr = new Bits(1).Value;
        _load = new Bits(1).Value;
        _store = new Bits(4).Value;
        _noStore = 15 * _store;
        _err = new Bits(1).Value;
        _setPc = new Bits(1).Value;
        _pcSource = new Bits(2).Value;
        _pcSourcePcPlusImm12b = 0;
        _pcSourcePcPlusImm20j = _pcSource;
        _pcSourceSource1RegDataPlusImm12i = 2 * _pcSource;
        _pcSourceSavedPc = 3 * _pcSource;
        _addressSource = new Bits(2).Value;
        _registersWrDataSource = new Bits(1).Value;
        _registersWrDataSourceDataLoadF = 0;
        _registersWrDataSourceAluOut = _registersWrDataSource;
        _inInterruptClear = new Bits(1).Value;
        _aluClk = new Bits(1).Value;
        _aluOp1Source = new Bits(2).Value;
        _aluOp1SourceSource1RegData = 0;
        _aluOp1SourceImm20u = _aluOp1Source;
        _aluOp1Source4 = 2 * _aluOp1Source;
        _aluOp2Source = new Bits(3).Value;
        _aluOp2SourceImm12i = 0;
        _aluOp2SourceImm12iSigned = _aluOp2Source;
        _aluOp2SourceSource2RegData = 2 * _aluOp2Source;
        _aluOp2SourceSource2RegData40 = 3 * _aluOp2Source;
        _aluOp2SourceSourcePc = 4 * _aluOp2Source;
        _aluOp = new Bits(4).Value;
        _dataLoadSigned = new Bits(1).Value;
        _dataShift = new Bits(5).Value;
    }
    internal void GenerateCode()
    {
        var nop = _registersWr | _noStore;
        var error = _err | nop;

        var lines = new List<string>();
        for (var i = 0; i < CodeLength; i++)
        {
            var op = (DecoderCodeGenerator.Commands)(i >> 2);
            var address = i & 3;
            var v = op switch
            {
                DecoderCodeGenerator.Commands.Nop => nop,
                DecoderCodeGenerator.Commands.Reti => nop | _setPc | _pcSourceSavedPc,
                DecoderCodeGenerator.Commands.Jal => _setPc | _pcSourcePcPlusImm20j |
                                                     BuildAluOp(AluOp.Add, _aluOp1Source4, _aluOp2SourceSourcePc),
                DecoderCodeGenerator.Commands.Jalr => _setPc | _pcSourceSource1RegDataPlusImm12i |
                                                      BuildAluOp(AluOp.Add, _aluOp1Source4, _aluOp2SourceSourcePc),
                DecoderCodeGenerator.Commands.Br => nop | _setPc | _pcSourcePcPlusImm12b,
                DecoderCodeGenerator.Commands.Add => BuildAluOp(AluOp.Add, _aluOp1SourceSource1RegData, _aluOp2SourceSource2RegData),
                DecoderCodeGenerator.Commands.Addi => BuildAluOp(AluOp.Add, _aluOp1SourceSource1RegData, _aluOp2SourceImm12i),
                
                DecoderCodeGenerator.Commands.Sub => BuildAluOp(AluOp.Sub, _aluOp1SourceSource1RegData, _aluOp2SourceSource2RegData),

                DecoderCodeGenerator.Commands.Sll => BuildAluOp(AluOp.Sl, _aluOp1SourceSource1RegData, _aluOp2SourceSource2RegData40),
                DecoderCodeGenerator.Commands.Slli => BuildAluOp(AluOp.Sl, _aluOp1SourceSource1RegData, _aluOp2SourceImm12i),
                
                DecoderCodeGenerator.Commands.Slt => BuildAluOp(AluOp.Slt, _aluOp1SourceSource1RegData, _aluOp2SourceSource2RegData),
                DecoderCodeGenerator.Commands.Slti => BuildAluOp(AluOp.Slt, _aluOp1SourceSource1RegData, _aluOp2SourceImm12i),

                DecoderCodeGenerator.Commands.Sltu => BuildAluOp(AluOp.Sltu, _aluOp1SourceSource1RegData, _aluOp2SourceSource2RegData),
                DecoderCodeGenerator.Commands.Sltiu => BuildAluOp(AluOp.Sltu, _aluOp1SourceSource1RegData, _aluOp2SourceImm12i),

                DecoderCodeGenerator.Commands.Xor => BuildAluOp(AluOp.Xor, _aluOp1SourceSource1RegData, _aluOp2SourceSource2RegData),
                DecoderCodeGenerator.Commands.Xori => BuildAluOp(AluOp.Xor, _aluOp1SourceSource1RegData, _aluOp2SourceImm12i),

                DecoderCodeGenerator.Commands.Or => BuildAluOp(AluOp.Or, _aluOp1SourceSource1RegData, _aluOp2SourceSource2RegData),
                DecoderCodeGenerator.Commands.And => BuildAluOp(AluOp.And, _aluOp1SourceSource1RegData, _aluOp2SourceSource2RegData),

                DecoderCodeGenerator.Commands.Srl => BuildAluOp(AluOp.Sr, _aluOp1SourceSource1RegData, _aluOp2SourceSource2RegData),
                DecoderCodeGenerator.Commands.Srli => BuildAluOp(AluOp.Sr, _aluOp1SourceSource1RegData, _aluOp2SourceImm12i),

                DecoderCodeGenerator.Commands.Sra => BuildAluOp(AluOp.Sra, _aluOp1SourceSource1RegData, _aluOp2SourceSource2RegData),
                DecoderCodeGenerator.Commands.Srai => BuildAluOp(AluOp.Sra, _aluOp1SourceSource1RegData, _aluOp2SourceImm12i),

                DecoderCodeGenerator.Commands.Mul => BuildAluOp(AluOp.Mul, _aluOp1SourceSource1RegData, _aluOp2SourceSource2RegData),
                DecoderCodeGenerator.Commands.Mulh => BuildAluOp(AluOp.Mulh, _aluOp1SourceSource1RegData, _aluOp2SourceSource2RegData),
                DecoderCodeGenerator.Commands.Mulhsu => BuildAluOp(AluOp.Mulhsu, _aluOp1SourceSource1RegData, _aluOp2SourceSource2RegData),
                DecoderCodeGenerator.Commands.Mulhu => BuildAluOp(AluOp.Mulhu, _aluOp1SourceSource1RegData, _aluOp2SourceSource2RegData),

                //DecoderCodeGenerator.Commands.Div => BuildAluOp(AluOp.Div, _aluOp1SourceSource1RegData, _aluOp2SourceSource2RegData),
                //DecoderCodeGenerator.Commands.Divu => BuildAluOp(AluOp.Divu, _aluOp1SourceSource1RegData, _aluOp2SourceSource2RegData),

                //DecoderCodeGenerator.Commands.Rem => BuildAluOp(AluOp.Rem, _aluOp1SourceSource1RegData, _aluOp2SourceSource2RegData),
                //DecoderCodeGenerator.Commands.Remu => BuildAluOp(AluOp.Remu, _aluOp1SourceSource1RegData, _aluOp2SourceSource2RegData),
                
                _ => error,
            };
            lines.Add(v.ToString("X8"));
        }
        File.WriteAllLines("microcode.mem", lines);
    }

    private int BuildAluOp(AluOp op, int op1, int op2)
    {
        return _noStore | (_aluOp * (int)op) | _aluClk | _registersWrDataSourceAluOut | op1 | op2;
    }
}

internal struct Bits
{
    private static int _bit = 1;
    
    internal readonly int Value;

    internal Bits(int size)
    {
        Value = _bit;
        _bit <<= size;
    }
}
