﻿const int microcodeLength = 1024;

var registersWrOthers = new Bits(1);
var registersWrAlu = new Bits(1);
var load = new Bits(1);
var wrOthers = new Bits(1);
var wrAlu = new Bits(1);
var halt = new Bits(1);
var err = new Bits(1);
var fetch2 = new Bits(1);
var setPc = new Bits(1);

var pcSource = new Bits(3);
var pcSourcePcPlus2 = 0;
var pcSourcePcValue816 = pcSource.Value;
var pcSourcePcValue1116 = 2 * pcSource.Value;
var pcSourceSourceValue716 = 3 * pcSource.Value;
var pcSourceDataIn = 4 * pcSource.Value;
var pcSourceInstructionParameter = 5 * pcSource.Value;
var pcSourceValue10 = 6 * pcSource.Value;
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
var registersWrDataSourceSpPlus1 = 12 * registersWrDataSource.Value;

var registersWrAddressSource = new Bits(2);
var registersWrAddressSourceSourceReg = 0;
var registersWrAddressSourceDestReg = registersWrAddressSource.Value;
var registersWrAddressSourceDestRegPlus1 = 2 * registersWrAddressSource.Value;
var registersWrAddressSourceSp = 3 * registersWrAddressSource.Value;

var stageResetNoMul = new Bits(1);
var stageResetMul = new Bits(1);

var aluOp1Source = new Bits(1);
var aluOp2Source = new Bits(1);
var aluOpIdSource = new Bits(2);
var aluClk = new Bits(1);
var inInterruptClear = new Bits(1);

var noRegistersWr = registersWrOthers.Value | registersWrAlu.Value;
var noWr = wrOthers.Value | wrAlu.Value;

var nextPc = setPc.Value | pcSourcePcPlus1;
var nextPc2 = setPc.Value | pcSourcePcPlus2;
var error = noRegistersWr | noWr | halt.Value | err.Value;

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
        // jmp addr16
        3 => conditionPass ? Jmp(stage) : Nop2(stage),
        >= 4 and <= 7 => Mvil(stage),
        >= 8 and <= 11 => Mvih(stage),
        >= 12 and <= 15 => conditionPass ? Br(stage) : Nop(stage),
        // call addr16
        16 => conditionPass ? Call(stage) : Nop2(stage),
        // ret
        17 => conditionPass ? Ret(stage, 0) : Nop(stage),
        // reti
        18 => Ret(stage, inInterruptClear.Value),
        // int
        19 => Call1(stage, pcSourceValue10),
        >= 20 and <= 22 => MovMImm(postInc, preDec, stage),
        // 23?
        // jmp11
        >= 24 and <= 25 => Jmp1(stage, pcSourcePcValue1116),
        // call11
        >= 26 and <= 27 => Call1(stage, pcSourcePcValue1116),
        >= 28 and <= 30 => AluRM(postInc, preDec, stage),
        // jmp reg
        31 => JmpReg(stage),
        // jmp (reg)
        >= 32 and <= 34 => JmpPReg(postInc, preDec, stage),
        // call reg
        35 => CallReg(stage),
        // call (reg)
        >= 36 and <= 38 => CallPReg(postInc, preDec, stage),
        39 => Pushf(stage),
        >= 40 and <= 42 => MovRM(postInc, preDec, stage),
        43 => Movrr(stage),
        >= 44 and <= 46 => MovMR(postInc, preDec, stage),
        //47?
        >= 48 and <= 55 => AluRR(stage),
        >= 56 and <= 58 => AluMR(postInc, preDec, stage),
        59 => AluRImm(stage),
        >= 60 and <= 62 => AluMImm(postInc, preDec, stage),
        //63?
        _ => error,
    };
    Console.WriteLine("{0:X8}", v);
}

return;

int Mvil(int stage)
{
    return stage switch
    {
        0 => registersWrAlu.Value | noWr | nextPc | registersWrDataSourceRegLo | registersWrAddressSourceSourceReg,
        1 => noRegistersWr | noWr | stageResetMul.Value | stageResetNoMul.Value,
        _ => error
    };
}

int Mvih(int stage)
{
    return stage switch
    {
        0 => registersWrAlu.Value | noWr | nextPc | registersWrDataSourceRegHi | registersWrAddressSourceSourceReg,
        1 => noRegistersWr | noWr | stageResetMul.Value | stageResetNoMul.Value,
        _ => error
    };
}

int MovRImm(int stage)
{
    return stage switch
    {
        0 => noRegistersWr | noWr | nextPc,
        1 => registersWrAlu.Value |noWr | fetch2.Value | nextPc | registersWrDataSourceDataIn | registersWrAddressSourceSourceReg,
        2 => noRegistersWr | noWr | stageResetMul.Value | stageResetNoMul.Value,
        _ => error
    };
}

int MovMImm(bool postInc, bool preDec, int stage)
{
    //todo
    return Hlt(stage);
}


int Jmp(int stage)
{
    return stage switch
    {
        0 => noRegistersWr | noWr | nextPc,
        1 => noRegistersWr | noWr | fetch2.Value | setPc.Value | pcSourceDataIn,
        2 => noRegistersWr | noWr | stageResetMul.Value | stageResetNoMul.Value,
        _ => error
    };
}

int Jmp1(int stage, int source)
{
    return stage switch
    {
        0 => noRegistersWr | noWr | setPc.Value | source,
        2 => noRegistersWr | noWr | stageResetMul.Value | stageResetNoMul.Value,
        _ => error
    };
}

int Call(int stage)
{
    return stage switch
    {
        // pc = pc + 1; sp = sp - 1
        0 => registersWrAlu.Value | noWr | nextPc | registersWrDataSourceSpMinus1 | registersWrAddressSourceSp,
        // load second command byte, set new address source, data_out = pc + 1
        1 => noRegistersWr | noWr | fetch2.Value,
        2 => noRegistersWr | noWr | addressSourceSpdata | dataOutSourcePcPlus1,
        // save pc, set new pc
        3 => noRegistersWr | wrAlu.Value | addressSourceSpdata | dataOutSourcePcPlus1 | setPc.Value | pcSourceInstructionParameter,
        // stage reset
        4 => noRegistersWr | noWr | stageResetMul.Value | stageResetNoMul.Value,
        _ => error
    };
}

int Call1(int stage, int pcSource)
{
    return stage switch
    {
        // pc = pc + 1; sp = sp - 1
        0 => registersWrAlu.Value | noWr | nextPc | registersWrDataSourceSpMinus1 | registersWrAddressSourceSp,
        // set new address source, data_out = pc + 1
        1 => noRegistersWr | noWr | addressSourceSpdata | dataOutSourcePcPlus1,
        // save pc, set new pc
        2 => noRegistersWr | wrAlu.Value | addressSourceSpdata | dataOutSourcePcPlus1 | setPc.Value | pcSource,
        // stage reset
        3 => noRegistersWr | noWr | stageResetMul.Value | stageResetNoMul.Value,
        _ => error
    };
}

int Ret(int stage, int flags)
{
    return stage switch
    {
        0 => noRegistersWr | noWr | addressSourceSpdata | flags,
        1 => registersWrAlu.Value | noWr | addressSourceSpdata | load.Value | setPc.Value | pcSourceDataIn |
             registersWrDataSourceSpPlus1 | registersWrAddressSourceSp,
        2 => noRegistersWr | noWr | stageResetMul.Value | stageResetNoMul.Value,
        _ => error
    };
}

int Br(int stage)
{
    return stage switch
    {
        0 => noRegistersWr | noWr | setPc.Value | pcSourcePcValue816,
        1 => noRegistersWr | noWr | stageResetMul.Value | stageResetNoMul.Value,
        _ => error
    };
}

int JmpPReg(bool postInc, bool preDec, int stage)
{
    //todo
    return Hlt(stage);
}

int CallPReg(bool postInc, bool preDec, int stage)
{
    //todo
    return Hlt(stage);
}

int MovRM(bool postInc, bool preDec, int stage)
{
    //todo
    return Hlt(stage);
}

int MovMR(bool postInc, bool preDec, int stage)
{
    //todo
    return Hlt(stage);
}

int AluMR(bool postInc, bool preDec, int stage)
{
    //todo
    return Hlt(stage);
}

int AluRM(bool postInc, bool preDec, int stage)
{
    //todo
    return Hlt(stage);
}

int AluMImm(bool postInc, bool preDec, int stage)
{
    //todo
    return Hlt(stage);
}

int AluRR(int stage)
{
    //todo
    return Hlt(stage);
}

int AluRImm(int stage)
{
    //todo
    return Hlt(stage);
}

int JmpReg(int stage)
{
    //todo
    return Hlt(stage);
}

int CallReg(int stage)
{
    //todo
    return Hlt(stage);
}

int Pushf(int stage)
{
    //todo
    return Hlt(stage);
}

int Movrr(int stage)
{
    //todo
    return Hlt(stage);
}

int Hlt(int stage)
{
    return stage == 0 ? noRegistersWr | noWr | halt.Value | stageResetMul.Value | stageResetNoMul.Value : error;
}

int Nop(int stage)
{
    return stage switch
    {
        0 => noRegistersWr | noWr | nextPc,
        1 => noRegistersWr | noWr | stageResetMul.Value | stageResetNoMul.Value,
        _ => error
    };
}

int Nop2(int stage)
{
    return stage switch
    {
        0 => noRegistersWr | noWr | nextPc2,
        1 => noRegistersWr | noWr | stageResetMul.Value | stageResetNoMul.Value,
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
