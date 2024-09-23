using System.Net;

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
var registersWrDataSpMinus1 = 5 * registersWrDataSource.Value;
var registersWrDataDataIn = 6 * registersWrDataSource.Value;
var registersWrDataAluOut = 7 * registersWrDataSource.Value;
var registersWrDataAluOut2 = 8 * registersWrDataSource.Value;
var registersWrDataAluOutPlusAdder = 9 * registersWrDataSource.Value;
var registersWrDataDestRegPlus1 = 10 * registersWrDataSource.Value;
var registersWrDataSourceRegPlus1 = 11 * registersWrDataSource.Value;

var registersWrAddressSource = new Bits(2);

var stageResetNoMul = new Bits(1);
var stageResetMul = new Bits(1);

var aluOp1Source = new Bits(1);
var aluOp2Source = new Bits(2);
var aluOpIdSource = new Bits(1);
var aluClk = new Bits(1);

var nextPc = setPc.Value | pcSourcePcPlus1 | stageResetMul.Value | stageResetNoMul.Value;
var error = registersWr.Value | wr.Value | halt.Value | err.Value;

for (var i = 0; i < microcodeLength; i++)
{
    var opcode = i >> 3;
    var stage = i & 7;
    var postInc = (opcode & 4) != 0;
    var preDec = (opcode & 2) != 0;
    var conditionPass = (opcode & 1) != 0;
    var v = opcode switch
    {
        // hlt
        0 => Hlt(stage),
        //nop
        1 => Nop(stage),
        _ => error,
    };
    Console.WriteLine("{0:X7}", v);
}

return;

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
