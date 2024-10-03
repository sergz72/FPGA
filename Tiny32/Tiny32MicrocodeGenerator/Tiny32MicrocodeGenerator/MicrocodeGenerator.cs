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
    private readonly int _pcSourcePcPlusImm20j, _pcSourceSource1RegDataPlusImm12i, _pcSourceSavedPc;
    private readonly int _registersWrDataSource, _registersWrDataSourceDataLoadF, _noStore;
    private readonly int _registersWrDataSourceAluOut, _inInterruptClear, _aluClk, _aluOp1Source;
    private readonly int _aluOp1SourceSource1RegData, _aluOp1SourceImm20u, _aluOp1Source4, _aluOp2Source;
    private readonly int _aluOp2SourceImm12i, _aluOp2SourceImm12iSigned, _aluOp2SourceSource2RegData;
    private readonly int _aluOp2SourceSource2RegData40, _aluOp2SourceSourcePc, _aluOp2SourceZero;
    private readonly int _aluOp, _dataSelector, _dataSelectorByte1Signed, _dataSelectorByte2Signed;
    private readonly int _dataSelectorByte3Signed, _dataSelectorByte4Signed, _dataSelectorByte1UnSigned;
    private readonly int _dataSelectorByte2UnSigned, _dataSelectorByte3UnSigned, _dataSelectorByte4UnSigned;
    private readonly int _dataSelectorHalf1Signed, _dataSelectorHalf2Signed, _dataSelectorHalf1UnSigned;
    private readonly int _dataSelectorHalf2UnSigned, _dataSelectorWord;
    private readonly int _dataByte2, _dataHalf2, _dataByte4, _dataWord;

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
        _aluOp2SourceZero = 5 * _aluOp2Source;
        _aluOp = new Bits(5).Value;
        _dataSelector = new Bits(4).Value;
        _dataSelectorByte1Signed = 0;
        _dataSelectorByte1UnSigned = _dataSelector;
        _dataSelectorByte2Signed = 2 * _dataSelector;
        _dataSelectorByte2UnSigned = 3 * _dataSelector;
        _dataSelectorByte3Signed = 4 * _dataSelector;
        _dataSelectorByte3UnSigned = 5 * _dataSelector;
        _dataSelectorByte4Signed = 6 * _dataSelector;
        _dataSelectorByte4UnSigned = 7 * _dataSelector;
        _dataSelectorHalf1Signed = 8 * _dataSelector;
        _dataSelectorHalf1UnSigned = 9 * _dataSelector;
        _dataSelectorHalf2Signed = 10 * _dataSelector;
        _dataSelectorHalf2UnSigned = 11 * _dataSelector;
        _dataSelectorWord = 12 * _dataSelector;
        _dataWord = 0;
        _dataByte2 = 1 * _dataSelector;
        _dataHalf2 = 2 * _dataSelector;
        _dataByte4 = 3 * _dataSelector;
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
                DecoderCodeGenerator.Commands.Wfi => nop,
                DecoderCodeGenerator.Commands.Reti => nop | _setPc | _pcSourceSavedPc,
                DecoderCodeGenerator.Commands.Hlt => nop,

                DecoderCodeGenerator.Commands.Jal => _setPc | _pcSourcePcPlusImm20j |
                                                     BuildAluOp(AluOp.Add, _aluOp1Source4, _aluOp2SourceSourcePc),
                DecoderCodeGenerator.Commands.Jalr => _setPc | _pcSourceSource1RegDataPlusImm12i |
                                                      BuildAluOp(AluOp.Add, _aluOp1Source4, _aluOp2SourceSourcePc),
                DecoderCodeGenerator.Commands.Br => nop | _setPc | _pcSourcePcPlusImm12b |
                                                    BuildAluOp(AluOp.Sub, _aluOp1SourceSource1RegData, _aluOp2SourceSource2RegData),
                
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

                DecoderCodeGenerator.Commands.Div => BuildAluOp(AluOp.Div, _aluOp1SourceSource1RegData, _aluOp2SourceSource2RegData),
                DecoderCodeGenerator.Commands.Divu => BuildAluOp(AluOp.Divu, _aluOp1SourceSource1RegData, _aluOp2SourceSource2RegData),

                DecoderCodeGenerator.Commands.Rem => BuildAluOp(AluOp.Rem, _aluOp1SourceSource1RegData, _aluOp2SourceSource2RegData),
                DecoderCodeGenerator.Commands.Remu => BuildAluOp(AluOp.Remu, _aluOp1SourceSource1RegData, _aluOp2SourceSource2RegData),

                DecoderCodeGenerator.Commands.Lb => address switch
                {
                    0 => _noStore | _load | _registersWrDataSourceDataLoadF | _dataSelectorByte1Signed,
                    1 => _noStore | _load | _registersWrDataSourceDataLoadF | _dataSelectorByte2Signed,
                    2 => _noStore | _load | _registersWrDataSourceDataLoadF | _dataSelectorByte3Signed,
                    _ => _noStore | _load | _registersWrDataSourceDataLoadF | _dataSelectorByte4Signed
                },
                DecoderCodeGenerator.Commands.Lbu => address switch
                {
                    0 => _noStore | _load | _registersWrDataSourceDataLoadF | _dataSelectorByte1UnSigned,
                    1 => _noStore | _load | _registersWrDataSourceDataLoadF | _dataSelectorByte2UnSigned,
                    2 => _noStore | _load | _registersWrDataSourceDataLoadF | _dataSelectorByte3UnSigned,
                    _ => _noStore | _load | _registersWrDataSourceDataLoadF | _dataSelectorByte4UnSigned
                },
                DecoderCodeGenerator.Commands.Lw => 
                    address == 0 ? _noStore | _load | _registersWrDataSourceDataLoadF | _dataSelectorWord : error,
                DecoderCodeGenerator.Commands.Lh => address switch
                {
                    0 => _noStore | _load | _registersWrDataSourceDataLoadF | _dataSelectorHalf1Signed,
                    2 => _noStore | _load | _registersWrDataSourceDataLoadF | _dataSelectorHalf2Signed,
                    _ => error
                },
                DecoderCodeGenerator.Commands.Lhu => address switch
                {
                    0 => _noStore | _load | _registersWrDataSourceDataLoadF | _dataSelectorHalf1UnSigned,
                    2 => _noStore | _load | _registersWrDataSourceDataLoadF | _dataSelectorHalf2UnSigned,
                    _ => error
                },

                DecoderCodeGenerator.Commands.Lui => BuildAluOp(AluOp.Add, _aluOp1SourceImm20u, _aluOp2SourceZero),
                DecoderCodeGenerator.Commands.Auipc => BuildAluOp(AluOp.Add, _aluOp1SourceImm20u, _aluOp2SourceSourcePc),

                DecoderCodeGenerator.Commands.Sb => address switch
                {
                    0 => _registersWr | 0x0E * _store | _registersWrDataSourceDataLoadF | _dataWord,
                    1 => _registersWr | 0x0D * _store | _registersWrDataSourceDataLoadF | _dataByte2,
                    2 => _registersWr | 0x0B * _store | _registersWrDataSourceDataLoadF | _dataHalf2,
                    _ => _registersWr | 0x08 * _store | _registersWrDataSourceDataLoadF | _dataByte4
                },
                DecoderCodeGenerator.Commands.Sw =>
                    address == 0 ? _registersWr | _registersWrDataSourceDataLoadF | _dataWord : error,
                DecoderCodeGenerator.Commands.Sh => address switch
                {
                    0 => _registersWr | 0x0C * _store | _registersWrDataSourceDataLoadF | _dataWord,
                    2 => _registersWr | 0x03 * _store | _registersWrDataSourceDataLoadF | _dataHalf2,
                    _ => error
                },
                
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
