using Cpu16EmulatorCommon;

namespace Cpu16EmulatorCpus;

public class ForthCPU(string[] code, int speed, int dataStackSize, int callStackSize,
                        int parametersStackSize, string[]? cpuOptions): Cpu(code, speed, 0)
{
    private const byte PUSH = 0;
    private const byte DUP  = 1;
    private const byte SET  = 2;
    private const byte JMP  = 3;
    private const byte GET  = 4;
    private const byte CALL = 5;
    private const byte RET  = 6;
    private const byte RETN = 7;
    private const byte HLT  = 8;
    private const byte WFI  = 9;
    private const byte BR   = 10;
    private const byte BR0  = 11;
    private const byte RETI = 12;
    private const byte DROP = 13;
    private const byte SWAP = 14;
    private const byte ROT  = 15;
    private const byte OVER = 16;
    private const byte LOOP = 17;
    private const byte PSTACK_PUSH = 18;
    private const byte PSTACK_GET  = 19;
    private const byte LOCAL_GET   = 20;
    private const byte LOCAL_SET   = 21;
    private const byte LOCALS      = 22;
    private const byte UPDATE_PSTACK_POINTER = 23;
    private const byte ALU_OP      = 0xF0;

    private const byte ALU_OP_ADD  = 0;
    private const byte ALU_OP_SUB  = 1;
    private const byte ALU_OP_AND  = 2;
    private const byte ALU_OP_OR   = 3;
    private const byte ALU_OP_XOR  = 4;
    private const byte ALU_OP_EQ   = 5;
    private const byte ALU_OP_NE   = 6;
    private const byte ALU_OP_GT   = 7;
    private const byte ALU_OP_GE   = 8;
    private const byte ALU_OP_LE   = 9;
    private const byte ALU_OP_LT   = 10;
    private const byte ALU_OP_SHL  = 11;
    private const byte ALU_OP_SHR  = 12;
    private const byte ALU_OP_MUL  = 13;
    private const byte ALU_OP_DIV  = 14;
    private const byte ALU_OP_REM  = 15;
    
    private ushort _savedPc;
    
    private readonly bool _hardMul = cpuOptions?.Contains("MUL") ?? false;
    private readonly bool _hardDiv = cpuOptions?.Contains("DIV") ?? false;
    private readonly bool _trace = cpuOptions?.Contains("TRACE") ?? false;
    
    public uint InterruptAck { get; private set; }

    public readonly ForthStack<ushort> DataStack = new("data", dataStackSize);
    public readonly ForthStack<ushort> CallStack = new("call", callStackSize);
    public readonly ForthStack<ushort> ParametersStack = new("parameters", parametersStackSize);
    
    public override void Reset()
    {
        base.Reset();
        DataStack.Clear();
        CallStack.Clear();
        ParametersStack.Clear();
    }

    protected override ushort? IsCall(uint instruction)
    {
        return instruction == CALL ? (ushort)(Pc + 3) : null;
    }

    private ushort BuildWord()
    {
        var b1 = (ushort)Code[Pc].Instruction;
        Pc = (ushort)(Pc + 1);
        var b2 = (ushort)Code[Pc].Instruction;
        Pc = (ushort)(Pc + 1);
        return (ushort)(b1 | (b2 << 8));
    }
    
    public override void Step()
    {
        base.Step();

        if (_trace)
            Logger?.Debug($"Step: {Pc:X4} {Wfi}");
        
        if (Error | Hlt)
            return;

        if (Interrupt != 0 && InterruptAck == 0)
        {
            InterruptAck = Interrupt;
            Wfi = false;
            _savedPc = Pc;
            Pc = (ushort)(Interrupt >= 2 ? 8 : 4);
        }
        
        if (Wfi)
            return;
        
        var instruction = (byte)Code[Pc].Instruction;
        Pc = (ushort)(Pc + 1);

        ushort address, data, data2;
        IoEvent ev;
        switch (instruction)
        {
            case PUSH:
                DataStack.Push(BuildWord(), Pc);
                break;
            case DUP:
                DataStack.Push(DataStack.Peek(Pc), Pc);
                break;
            case SET:
                if (IoWriteEventHandler == null)
                    throw new CpuException("null IoWriteEventHandler");
                address = DataStack.Pop(Pc);
                data = DataStack.Pop(Pc);
                ev = new IoEvent { Address = address, Data = data };
                IoWriteEventHandler.Invoke(this, ev);
                break;
            case JMP:
                Pc = BuildWord();
                break;
            case GET:
                if (IoReadEventHandler == null)
                    throw new CpuException("null IoReadEventHandler");
                address = DataStack.Pop(Pc);
                ev = new IoEvent { Address = address };
                IoReadEventHandler.Invoke(this, ev);
                DataStack.Push(ev.Data, Pc);
                break;
            case CALL:
                CallStack.Push((ushort)(Pc + 2), Pc);
                Pc = BuildWord();
                break;
            case RET:
                Pc = CallStack.Pop(Pc);
                break;
            case RETN:
                data = (ushort)Code[Pc].Instruction;
                CallStack.DropN(data, Pc);
                Pc = CallStack.Pop(Pc);
                break;
            case HLT:
                Logger?.Info($"{Ticks}: HLT {Pc:X4}");
                Hlt = true;
                break;
            case WFI:
                Logger?.Info($"{Ticks}: WFI {Pc:X4}");
                Wfi = true;
                break;
            case BR:
                data = DataStack.Pop(Pc);
                if (data != 0)
                    Pc = BuildWord();
                else
                    Pc = (ushort)(Pc + 2);
                break;
            case BR0:
                data = DataStack.Pop(Pc);
                if (data == 0)
                    Pc = BuildWord();
                else
                    Pc = (ushort)(Pc + 2);
                break;
            case RETI:
                InterruptAck = 0;
                Pc = _savedPc;
                break;
            case DROP:
                DataStack.Pop(Pc);
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
            case LOOP:
                data = DataStack.Pop(Pc);
                data2 = ParametersStack.Pop(Pc);
                var v = (ushort)(data + data2);
                if (v >= ParametersStack.Peek(Pc))
                {
                    ParametersStack.Pop(Pc);
                    Pc = (ushort)(Pc + 2);
                }
                else
                {
                    ParametersStack.Push(v, Pc);
                    Pc = BuildWord();
                }
                break;
            case PSTACK_PUSH:
                data = DataStack.Pop(Pc);
                data2 = DataStack.Pop(Pc);
                ParametersStack.Push(data2, Pc);
                ParametersStack.Push(data, Pc);
                break;
            case PSTACK_GET:
                data = (ushort)Code[Pc].Instruction;
                Pc = (ushort)(Pc + 1); 
                data  = ParametersStack.GetN(data, Pc);
                DataStack.Push(data, Pc);
                break;
            case LOCAL_GET:
                data = (ushort)Code[Pc].Instruction;
                Pc = (ushort)(Pc + 1);
                data = CallStack.GetN(data, Pc);
                DataStack.Push(data, Pc);
                break;
            case LOCAL_SET:
                data = (ushort)Code[Pc].Instruction;
                Pc = (ushort)(Pc + 1); 
                CallStack.SetN(data, DataStack.Pop(Pc), Pc);
                break;
            case LOCALS:
                data = (ushort)Code[Pc].Instruction;
                Pc = (ushort)(Pc + 1); 
                CallStack.IncrementPointer(data, Pc);
                break;
            case UPDATE_PSTACK_POINTER:
                data = (ushort)Code[Pc].Instruction;
                Pc = (ushort)(Pc + 1); 
                ParametersStack.DropN(data, Pc);
                break;
            default:
                if ((instruction & ALU_OP) == ALU_OP)
                {
                    data2 = DataStack.Pop(Pc);
                    data = DataStack.Pop(Pc);
                    switch (instruction & ~ALU_OP)
                    {
                        case ALU_OP_ADD:
                            DataStack.Push((ushort)(data + data2), Pc);
                            break;
                        case ALU_OP_SUB:
                            DataStack.Push((ushort)(data - data2), Pc);
                            break;
                        case ALU_OP_AND:
                            DataStack.Push((ushort)(data & data2), Pc);
                            break;
                        case ALU_OP_OR:
                            DataStack.Push((ushort)(data | data2), Pc);
                            break;
                        case ALU_OP_XOR:
                            DataStack.Push((ushort)(data ^ data2), Pc);
                            break;
                        case ALU_OP_EQ:
                            DataStack.Push(data == data2 ? (ushort)1 : (ushort)0, Pc);
                            break;
                        case ALU_OP_NE:
                            DataStack.Push(data != data2 ? (ushort)1 : (ushort)0, Pc);
                            break;
                        case ALU_OP_GT:
                            DataStack.Push(data > data2 ? (ushort)1 : (ushort)0, Pc);
                            break;
                        case ALU_OP_GE:
                            DataStack.Push(data >= data2 ? (ushort)1 : (ushort)0, Pc);
                            break;
                        case ALU_OP_LE:
                            DataStack.Push(data <= data2 ? (ushort)1 : (ushort)0, Pc);
                            break;
                        case ALU_OP_LT:
                            DataStack.Push(data < data2 ? (ushort)1 : (ushort)0, Pc);
                            break;
                        case ALU_OP_SHL:
                            DataStack.Push((ushort)(data << data2), Pc);
                            break;
                        case ALU_OP_SHR:
                            DataStack.Push((ushort)(data >> data2), Pc);
                            break;
                        case ALU_OP_MUL:
                            if (_hardMul)
                                DataStack.Push((ushort)(data * data2), Pc);
                            else
                            {
                                Logger?.Error($"{Ticks}: ERROR");
                                Error = true;
                            }
                            break;
                        case ALU_OP_DIV:
                            if (_hardDiv)
                                DataStack.Push((ushort)(data / data2), Pc);
                            else
                            {
                                Logger?.Error($"{Ticks}: ERROR {Pc:X4}");
                                Error = true;
                            }
                            break;
                        case ALU_OP_REM:
                            if (_hardDiv)
                                DataStack.Push((ushort)(data % data2), Pc);
                            else
                            {
                                Logger?.Error($"{Ticks}: ERROR {Pc:X4}");
                                Error = true;
                            }
                            break;
                        default:
                            Logger?.Error($"{Ticks}: ERROR {Pc:X4}");
                            Error = true;
                            break;
                    }
                }
                else
                {
                    Logger?.Error($"{Ticks}: ERROR {Pc:X4}");
                    Error = true;
                }
                break;
        }
    }
}

public sealed class ForthStack<T>(string name, int size)
{
    public readonly T[] Contents = new T[size];

    public int Pointer { get; private set; }

    internal void Push(T value, ushort pc)
    {
        Pointer++;
        if (Pointer >= size)
            throw new CpuException($"{name} stack overflow at {pc:X4}");
        Contents[Pointer] = value;
    }

    internal T Peek(ushort pc)
    {
        if (Pointer <= 0)
            throw new CpuException($"{name} stack underflow at {pc:X4}");
        return Contents[Pointer];
    }

    internal T Pop(ushort pc)
    {
        if (Pointer <= 0)
            throw new CpuException($"{name} stack underflow at {pc:X4}");
        return Contents[Pointer--];
    }

    internal T GetN(int n, ushort pc)
    {
        if (Pointer < n)
            throw new CpuException($"{name} stack underflow at {pc:X4}");
        return Contents[Pointer - n];
    }
    
    internal void SetN(int n, T value, ushort pc)
    {
        if (Pointer < n)
            throw new CpuException($"{name} stack underflow at {pc:X4}");
        Contents[Pointer - n] = value;
    }

    internal void DropN(int n, ushort pc)
    {
        if (Pointer < n)
            throw new CpuException($"{name} stack underflow at {pc:X4}");
        Pointer -= n;
    }
    
    internal void Clear()
    {
        Pointer = 0;
    }

    public void IncrementPointer(ushort data, ushort pc)
    {
        Pointer += data;
        if (Pointer >= size)
            throw new CpuException($"{name} stack overflow at {pc:X4}");
    }
}