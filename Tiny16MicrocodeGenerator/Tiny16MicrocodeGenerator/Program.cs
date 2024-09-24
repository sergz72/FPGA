const int microcodeLength = 1024;

var registersWr = new Bits(1);
var load = new Bits(1);
var wr = new Bits(1);
var halt = new Bits(1);
var err = new Bits(1);
var fetch2 = new Bits(1);
var setPc = new Bits(1);

var pcSource = new Bits(3);
var pcSourcePcPlus2 = 0;
var pcSourcePcValue816 = pcSource.Value;
var pcSourcePcValue1116 = 2 * pcSource.Value;
var pcSourceSourceValue716 = 3 * pcSource.Value;
var pcSourceInstructionParameter = 4 * pcSource.Value;
var pcSourcePcPlus1 = 7 * pcSource.Value;

var addressSource = new Bits(2);
var addressSourcePc = 0;
var addressSourceSpdata = addressSource.Value;
var addressDataWrValue2 = 2 * addressSource.Value;
var addressDataWrValue4 = 3 * addressSource.Value;

var dataOutSource = new Bits(2);
var dataOutSourceSourceReg = 0;
var dataOutSourceInstructionParameter = dataOutSource.Value;
var dataOutSourceFlags = 2 * dataOutSource.Value;
var dataOutSourcePcPlus1 = 3 * dataOutSource.Value;

var registersWrDataSource = new Bits(4);
var registersWrDataSourceRegValue416 = 0;
var registersWrDataSourceRegHi = registersWrDataSource.Value;
var registersWrDataSourceRegLo = 2 * registersWrDataSource.Value;
var registersWrDataDestRegMinus1 = 3 * registersWrDataSource.Value;
var registersWrDataSourceRegMinus1 = 4 * registersWrDataSource.Value;
var registersWrDataSourceSpMinus1 = 5 * registersWrDataSource.Value;
var registersWrDataSourceDataIn = 6 * registersWrDataSource.Value;
var registersWrDataSourceAluOut = 7 * registersWrDataSource.Value;
var registersWrDataSourceAluOut2 = 8 * registersWrDataSource.Value;
var registersWrDataSourceAluOutPlusAdder = 9 * registersWrDataSource.Value;
var registersWrDataSourceDestRegPlus1 = 10 * registersWrDataSource.Value;
var registersWrDataSourceSourceRegPlus1 = 11 * registersWrDataSource.Value;

var registersWrAddressSource = new Bits(2);
var registersWrAddressSourceSourceReg = 0;
var registersWrAddressSourceDestReg = registersWrAddressSource.Value;
var registersWrAddressSourceDestRegPlus1 = 2 * registersWrAddressSource.Value;
var registersWrAddressSourceSp = 3 * registersWrAddressSource.Value;

var stageResetNoMul = new Bits(1);
var stageResetMul = new Bits(1);

var aluOp1Source = new Bits(1);
var aluOp2Source = new Bits(2);
var aluOpIdSource = new Bits(1);
var aluClk = new Bits(1);

var nextPc = setPc.Value | pcSourcePcPlus1;
var nextPc2 = setPc.Value | pcSourcePcPlus2;
var error = registersWr.Value | wr.Value | halt.Value | err.Value;

for (var i = 0; i < microcodeLength; i++)
{
    var opcode = i >> 4;
    var conditionPass = (i & 8) != 0; 
    var stage = i & 7;
    var postInc = (opcode & 2) != 0;
    var preDec = (opcode & 1) != 0;
    var v = opcode switch
    {
        // hlt
        0 => Hlt(stage),
        //nop
        1 => Nop(stage),
        2 => MovRImm(stage),
        3 => conditionPass ? Jmp(stage) : Nop2(stage),
        >= 4 and <= 7 => Mvil(stage),
        >= 8 and <= 11 => Mvih(stage),
        _ => error,
    };
    Console.WriteLine("{0:X7}", v);
}

return;

int Mvil(int stage)
{
    return stage switch
    {
        0 => wr.Value | nextPc | registersWrDataSourceRegLo | registersWrAddressSourceSourceReg,
        1 => registersWr.Value | wr.Value | stageResetMul.Value | stageResetNoMul.Value,
        _ => error
    };
}

int Mvih(int stage)
{
    return stage switch
    {
        0 => wr.Value | nextPc | registersWrDataSourceRegHi | registersWrAddressSourceSourceReg,
        1 => registersWr.Value | wr.Value | stageResetMul.Value | stageResetNoMul.Value,
        _ => error
    };
}

int MovRImm(int stage)
{
    return stage switch
    {
        0 => registersWr.Value | wr.Value | nextPc,
        1 => wr.Value | fetch2.Value | nextPc | registersWrDataSourceDataIn | registersWrAddressSourceSourceReg,
        2 => registersWr.Value | wr.Value | stageResetMul.Value | stageResetNoMul.Value,
        _ => error
    };
}

int Jmp(int stage)
{
    return stage switch
    {
        0 => registersWr.Value | wr.Value | nextPc,
        1 => registersWr.Value | wr.Value | fetch2.Value | setPc.Value | pcSourceInstructionParameter,
        2 => registersWr.Value | wr.Value | stageResetMul.Value | stageResetNoMul.Value,
        _ => error
    };
}

int Hlt(int stage)
{
    return stage == 0 ? registersWr.Value | wr.Value | halt.Value | stageResetMul.Value | stageResetNoMul.Value : error;
}

int Nop(int stage)
{
    return stage switch
    {
        0 => registersWr.Value | wr.Value | nextPc,
        1 => registersWr.Value | wr.Value | stageResetMul.Value | stageResetNoMul.Value,
        _ => error
    };
}

int Nop2(int stage)
{
    return stage switch
    {
        0 => registersWr.Value | wr.Value | nextPc2,
        1 => registersWr.Value | wr.Value | stageResetMul.Value | stageResetNoMul.Value,
        _ => error
    };
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
