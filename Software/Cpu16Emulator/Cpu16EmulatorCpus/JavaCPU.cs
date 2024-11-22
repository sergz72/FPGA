using Cpu16EmulatorCommon;

namespace Cpu16EmulatorCpus;

internal static class Conditions
{
    internal const int Neg = 4;
    internal const int None = 4;
    internal const int LT = 2;
    internal const int GE = 2 + 4;
    internal const int EQ = 1;
    internal const int NE = 1 + 4;
    internal const int GT = 1 + 2 + 4; // not LT & not EQ
    internal const int LE = 1 + 2; // LT | EQ
    internal const int CMP_GT = 2;
    internal const int CMP_EQ = 1;
    internal const int CMP_NE = 1 + 4;
    internal const int CMP_LE = 2 + 4;
    internal const int CMP_LT = 1 + 2 + 4; // not GT & not EQ
    internal const int CMP_GE = 1 + 2; // GT | EQ
}

public class JavaCPU(string[] code, int speed, int dataStackSize, int callStackSize, string[]? cpuOptions):
    Cpu(code, speed)
{
    private const byte PUSH = 0;
    private const byte PUSH_LONG = 1;
    private const byte DUP  = 2;
    private const byte SET  = 3;
    private const byte SET_LONG  = 4;
    private const byte JMP  = 5;
    private const byte GET  = 6;
    private const byte GET_LONG  = 7;
    private const byte CALL = 8;
    private const byte CALL_INDIRECT = 9;
    private const byte RET  = 10;
    private const byte RETN = 11;
    private const byte HLT  = 12;
    private const byte WFI  = 13;
    private const byte NEG  = 14;
    private const byte INC  = 15;
    private const byte RETI = 16;
    private const byte DROP = 17;
    private const byte DROP2 = 18;
    private const byte SWAP = 19;
    private const byte ROT  = 20;
    private const byte OVER = 21;
    private const byte LOCAL_GET   = 22;
    private const byte LOCAL_SET   = 23;
    private const byte LOCALS      = 24;
    private const byte NOP = 25;
    private const byte GET_DATA_STACK_POINTER = 26;
    private const byte IFCMP = 27;
    private const byte IF = 28;
    private const byte ALU_OP = 29;
    private const byte ARRAYP = 30;
    private const byte ARRAYP2 = 31;
    private const byte BIPUSH = 32;
    private const byte SIPUSH = 33;
    private const byte GETN = 34;
    private const byte JMP_INDIRECT = 35;
    private const byte DIV = 36;
    private const byte REM = 37;

    private const byte ALU_OP_ADD  = 0;
    private const byte ALU_OP_SUB  = 1;
    private const byte ALU_OP_AND  = 2;
    private const byte ALU_OP_OR   = 3;
    private const byte ALU_OP_XOR  = 4;
    private const byte ALU_OP_SHL  = 5;
    private const byte ALU_OP_LLSHR  = 6;
    private const byte ALU_OP_ILSHR  = 7;
    private const byte ALU_OP_ASHR  = 8;
    private const byte ALU_OP_BIT_TEST = 9;
    private const byte ALU_OP_MUL  = 10;
    private const byte ALU_OP_CMP  = 11;

    private uint _savedPc;
    
    private readonly bool _trace = cpuOptions?.Contains("TRACE") ?? false;
    
    public uint InterruptAck { get; private set; }

    public readonly ForthStack<long> DataStack = new("data", dataStackSize);
    public readonly ForthStack<long> CallStack = new("call", callStackSize);
    
    public override void Reset()
    {
        base.Reset();
        DataStack.Clear();
        CallStack.Clear();
    }

    protected override uint? IsCall(uint instruction)
    {
        return instruction == CALL << 8 ? Pc + 3 : null;
    }

    private int BuildInt()
    {
        return (int)BuildWord();
    }

    private long BuildLong()
    {
        var w1 = (long)BuildWord();
        var w2 = (long)BuildWord();
        return (w2 << 32) | w1;
    }
    
    private uint BuildWord()
    {
        var b1 = Code[Pc].Instruction;
        Pc++;
        var b2 = Code[Pc].Instruction;
        Pc++;
        return b1 | (b2 << 16);
    }
    
    public override void Step()
    {
        base.Step();

        if (_trace)
        {
            Logger?.Debug($"Step: {Pc:X8} {Wfi}");
            Logger?.Info(DataStack.Dump("Data"));
        }

        if (Error | Hlt)
            return;

        if (Interrupt != 0 && InterruptAck == 0)
        {
            InterruptAck = Interrupt;
            Wfi = false;
            _savedPc = Pc;
            Pc = (uint)(Interrupt >= 2 ? 8 : 4);
        }
        
        if (Wfi)
            return;
        
        var instruction = (ushort)Code[Pc++].Instruction;

        long address, data, data2;
        IoEvent ev;
        switch (instruction >> 8)
        {
            case PUSH:
                DataStack.Push(BuildInt(), Pc);
                break;
            case SIPUSH:
                var s = (short)Code[Pc++].Instruction;
                DataStack.Push(s, Pc);
                break;
            case BIPUSH:
                var b = (sbyte)instruction;
                DataStack.Push(b, Pc);
                break;
            case PUSH_LONG:
                DataStack.Push(BuildLong(), Pc);
                break;
            case DUP:
                DataStack.Push(DataStack.Peek(Pc), Pc);
                break;
            case SET:
                if (IoWriteEventHandler == null)
                    throw new CpuException("null IoWriteEventHandler");
                address = DataStack.Pop(Pc);
                if (address == 0)
                {
                    Logger?.Error($"{Ticks}: ERROR {Pc:X8}");
                    Error = true;
                }
                else
                {
                    data = DataStack.Pop(Pc);
                    ev = new IoEvent { Address = (uint)address, Data = (uint)data };
                    IoWriteEventHandler.Invoke(this, ev);
                }
                break;
            case SET_LONG:
                if (IoWriteEventHandler == null)
                    throw new CpuException("null IoWriteEventHandler");
                address = DataStack.Pop(Pc);
                if (address == 0)
                {
                    Logger?.Error($"{Ticks}: ERROR {Pc:X8}");
                    Error = true;
                }
                else
                {
                    data = DataStack.Pop(Pc);
                    ev = new IoEvent { Address = (uint)address, Data = (uint)data };
                    IoWriteEventHandler.Invoke(this, ev);
                    ev = new IoEvent { Address = (uint)address + 1, Data = (uint)(data >> 32) };
                    IoWriteEventHandler.Invoke(this, ev);
                }
                break;
            case JMP:
                If(true);
                break;
            case GET:
                if (IoReadEventHandler == null)
                    throw new CpuException("null IoReadEventHandler");
                address = DataStack.Pop(Pc);
                if (address == 0)
                {
                    Logger?.Error($"{Ticks}: ERROR {Pc:X8}");
                    Error = true;
                }
                else
                {
                    ev = new IoEvent { Address = (uint)address };
                    IoReadEventHandler.Invoke(this, ev);
                    var d = (int)ev.Data;
                    DataStack.Push(d, Pc);
                }
                break;
            case GETN:
                if (IoReadEventHandler == null)
                    throw new CpuException("null IoReadEventHandler");
                address = DataStack.GetN(instruction & 0xFF, Pc);
                if (address == 0)
                {
                    Logger?.Error($"{Ticks}: ERROR {Pc:X8}");
                    Error = true;
                }
                else
                {
                    ev = new IoEvent { Address = (uint)address };
                    IoReadEventHandler.Invoke(this, ev);
                    var d = (int)ev.Data;
                    DataStack.Push(d, Pc);
                }
                break;
            case GET_LONG:
                if (IoReadEventHandler == null)
                    throw new CpuException("null IoReadEventHandler");
                address = DataStack.Pop(Pc);
                if (address == 0)
                {
                    Logger?.Error($"{Ticks}: ERROR {Pc:X8}");
                    Error = true;
                }
                else
                {
                    ev = new IoEvent { Address = (uint)address };
                    IoReadEventHandler.Invoke(this, ev);
                    var d1 = (long)ev.Data;
                    ev = new IoEvent { Address = (uint)address + 1 };
                    IoReadEventHandler.Invoke(this, ev);
                    var d2 = (long)ev.Data;
                    DataStack.Push((d2 << 32) | d1, Pc);
                }
                break;
            case CALL:
                CallStack.Push(Pc + 2, Pc);
                Pc = BuildWord();
                break;
            case RET:
                Pc = (uint)CallStack.Pop(Pc);
                break;
            case RETN:
                CallStack.DropN(instruction & 0xFF, Pc);
                Pc = (uint)CallStack.Pop(Pc);
                break;
            case HLT:
                Logger?.Info($"{Ticks}: HLT {Pc:X8}");
                Hlt = true;
                break;
            case WFI:
                Logger?.Info($"{Ticks}: WFI {Pc:X8}");
                Wfi = true;
                break;
            case RETI:
                InterruptAck = 0;
                CallStack.DropN(instruction & 0xFF, Pc);
                Pc = _savedPc;
                break;
            case DROP:
                DataStack.Pop(Pc);
                break;
            case DROP2:
                DataStack.DropN(2, Pc);
                break;
            case SWAP:
                data  = DataStack.Pop(Pc);
                data2 = DataStack.Pop(Pc);
                DataStack.Push(data, Pc);
                DataStack.Push(data2, Pc);
                break;
            case ROT:
                data  = DataStack.Pop(Pc);
                data2 = DataStack.Pop(Pc);
                var data3 = DataStack.Pop(Pc);
                DataStack.Push(data2, Pc);
                DataStack.Push(data, Pc);
                DataStack.Push(data3, Pc);
                break;
            case OVER:
                data  = DataStack.GetN(1, Pc);
                DataStack.Push(data, Pc);
                break;
            case LOCAL_GET:
                data = CallStack.GetN(instruction & 0xFF, Pc);
                DataStack.Push(data, Pc);
                break;
            case LOCAL_SET:
                CallStack.SetN(instruction & 0xFF, DataStack.Pop(Pc), Pc);
                break;
            case LOCALS:
                CallStack.IncrementPointer(instruction & 0xFF, Pc);
                break;
            case GET_DATA_STACK_POINTER:
                DataStack.Push(DataStack.Sp, Pc);
                break;
            case NOP:
                break;
            case NEG:
                DataStack.Push(-DataStack.Pop(Pc), Pc);
                break;
            case INC:
                var n = instruction & 0xFF;
                var v = CallStack.GetN(n, Pc);
                var plus = (short)(Code[Pc++].Instruction & 0xFFFF);
                CallStack.SetN(n, v + plus, Pc);
                break;
            case IF:
                data = DataStack.Pop(Pc);
                switch (instruction & 0xFF)
                {
                    case Conditions.EQ:
                        If(data == 0);
                        break;
                    case Conditions.NE:
                        If(data != 0);
                        break;
                    case Conditions.GE:
                        If(data >= 0);
                        break;
                    case Conditions.GT:
                        If(data > 0);
                        break;
                    case Conditions.LE:
                        If(data <= 0);
                        break;
                    case Conditions.LT:
                        If(data < 0);
                        break;
                    default:
                        Logger?.Error($"{Ticks}: ERROR {Pc:X8}");
                        Error = true;
                        break;
                }
                break;
            case IFCMP:
                data2 = DataStack.Pop(Pc);
                data = DataStack.Pop(Pc);
                switch (instruction & 0xFF)
                {
                    case Conditions.CMP_EQ:
                        If(data == data2);
                        break;
                    case Conditions.CMP_NE:
                        If(data != data2);
                        break;
                    case Conditions.CMP_GE:
                        If(data >= data2);
                        break;
                    case Conditions.CMP_GT:
                        If(data > data2);
                        break;
                    case Conditions.CMP_LE:
                        If(data <= data2);
                        break;
                    case Conditions.CMP_LT:
                        If(data < data2);
                        break;
                    default:
                        Logger?.Error($"{Ticks}: ERROR {Pc:X8}");
                        Error = true;
                        break;
                }
                break;
            case ARRAYP:
                data = DataStack.Pop(Pc);
                address = DataStack.Pop(Pc);
                if (address == 0)
                {
                    Logger?.Error($"{Ticks}: ERROR {Pc:X8}");
                    Error = true;
                }
                else
                    DataStack.Push(address + data + 1, Pc);
                break;
            case ARRAYP2:
                data = DataStack.Pop(Pc);
                address = DataStack.Pop(Pc);
                if (address == 0)
                {
                    Logger?.Error($"{Ticks}: ERROR {Pc:X8}");
                    Error = true;
                }
                else
                    DataStack.Push(address + (data << 1) + 1, Pc);
                break;
            case CALL_INDIRECT:
                if (IoReadEventHandler == null)
                    throw new CpuException("null IoReadEventHandler");
                address = DataStack.Pop(Pc);
                if (address == 0)
                {
                    Logger?.Error($"{Ticks}: ERROR {Pc:X8}");
                    Error = true;
                }
                else
                {
                    CallStack.Push(Pc, Pc);
                    address += instruction & 0xFF;
                    ev = new IoEvent { Address = (uint)address };
                    IoReadEventHandler.Invoke(this, ev);
                    Pc = ev.Data;
                }
                break;
            case DIV:
                data2 = DataStack.Pop(Pc);
                data = DataStack.Pop(Pc);
                DataStack.Push(data / data2, Pc);
                break;
            case REM:
                data2 = DataStack.Pop(Pc);
                data = DataStack.Pop(Pc);
                DataStack.Push(data % data2, Pc);
                break;
            case JMP_INDIRECT:
                var offset = (uint)DataStack.Pop(Pc);
                Pc += offset << 1;
                break;
            case ALU_OP:
                data2 = DataStack.Pop(Pc);
                data = DataStack.Pop(Pc);
                switch (instruction & 0xFF)
                {
                    case ALU_OP_ADD:
                        DataStack.Push(data + data2, Pc);
                        break;
                    case ALU_OP_SUB:
                        DataStack.Push(data - data2, Pc);
                        break;
                    case ALU_OP_AND:
                        DataStack.Push(data & data2, Pc);
                        break;
                    case ALU_OP_OR:
                        DataStack.Push(data | data2, Pc);
                        break;
                    case ALU_OP_XOR:
                        DataStack.Push(data ^ data2, Pc);
                        break;
                    case ALU_OP_SHL:
                        DataStack.Push(data << (int)data2, Pc);
                        break;
                    case ALU_OP_LLSHR:
                        DataStack.Push(data >>> (int)data2, Pc);
                        break;
                    case ALU_OP_ILSHR:
                        DataStack.Push((uint)data >>> (int)data2, Pc);
                        break;
                    case ALU_OP_ASHR:
                        DataStack.Push(data >> (int)data2, Pc);
                        break;
                    case ALU_OP_BIT_TEST:
                        DataStack.Push((data & (1 << ((int)data2 & 0x03F))) != 0 ? 1 : 0, Pc);
                        break;
                    case ALU_OP_MUL:
                        DataStack.Push(data * data2, Pc);
                        break;
                    case ALU_OP_CMP:
                        DataStack.Push(data > data2 ? 1 : data == data2 ? 0 : -1, Pc);
                        break;
                    default:
                        Logger?.Error($"{Ticks}: ERROR {Pc:X8}");
                        Error = true;
                        break;
                }
                break;
            default:
                Logger?.Error($"{Ticks}: ERROR {Pc:X8}");
                Error = true;
                break;
        }
    }

    private void If(bool pass)
    {
        if (pass)
        {
            var offset = (short)(Code[Pc].Instruction & 0xFFFF);
            var iOffset = (int)offset;
            Pc += (uint)iOffset;
        }
        else
            Pc++;
    }

    public override void Finish()
    {
        Console.WriteLine($"Data stack usage: {DataStack.MaxPointer}");
        Console.WriteLine($"Call stack usage: {CallStack.MaxPointer}");
    }
}
