const int microcodeLength = 1024;
const int stageReset = 1;
const int ioRd = 2;
const int ioWr = 4;
const int ioDataDirection = 8;
const int addressSet = 0x10;
const int addressLoad = 0x20;
const int addressSource = 0x40;
const int ioAddressSource = 0x80;
const int ioDataOutSource = 0x100;
const int aluClk = 0x200;
const int conditionNeg = 0x400;
const int conditonFlagN = 0x800;
const int conditonFlagZ = 0x1000;
const int conditonFlagC = 0x2000;
const int aluOp1SourceRegisters158 = 0x400;
const int aluOp1SourceRegisters2316 = 0;
const int aluOp2SourceRegisters3124 = 0;
const int aluOp2SourceInstruction3116 = 0x800;
const int aluOp2SourceIoData = 0x1000;
const int hlt = 0x4000;
const int error = 0x8000;
const int push = 0x10000;
const int pop = 0x20000;
const int setResult = 0x40000;
const int setResult2 = 0x80000;

for (var i = 0; i < microcodeLength; i++)
{
    var v = ioRd | ioWr | ioDataDirection;
    var stage = i & 3;
    var opType = i >> 6;
    v |= stage switch
    {
        0 => opType switch
        {
            0 => addressSet | addressLoad | addressSource | BuildCondition(i),
            1 => addressSet | addressLoad | BuildCondition(i),
            2 => addressSet | addressLoad | addressSource | push | BuildCondition(i),
            3 => addressSet | addressLoad | push | BuildCondition(i),
            4 => addressSet | addressLoad | pop | BuildCondition(i),
            _ => hlt | error
        },
        1 => opType switch
        {
            0 => stageReset,
            1 => stageReset,
            2 => stageReset,
            3 => stageReset,
            4 => stageReset,
            _ => hlt | error
        },
        2 => hlt | error,
        3 => 0,
        _ => 0
    };
    Console.WriteLine("{0:X5}", v);
}

return;

int BuildCondition(int i)
{
    return ((i >> 2) & 0xF) switch
    {
        // no condition
        0 => conditionNeg,
        // c == 1
        1 => conditonFlagC,
        // c == 0
        2 => conditonFlagC | conditionNeg,
        // z == 1
        3 => conditonFlagZ,
        // z == 0
        4 => conditonFlagZ | conditionNeg,
        // z == 0 && c == 0
        5 => conditonFlagC | conditonFlagZ | conditionNeg,
        // z == 1 || c == 1
        6 => conditonFlagC | conditonFlagZ,
        _ => hlt | error
    };
}