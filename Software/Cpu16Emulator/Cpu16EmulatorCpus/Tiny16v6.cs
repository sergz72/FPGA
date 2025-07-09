using Cpu16EmulatorCommon;

namespace Cpu16EmulatorCpus;

public class Tiny16v6: Cpu
{
    private const int ALU_OP_ADC  = 0;
    private const int ALU_OP_ADD  = 1;
    private const int ALU_OP_SBC  = 2;
    private const int ALU_OP_SUB  = 3;
    private const int ALU_OP_CMP  = 4;
    private const int ALU_OP_AND  = 5;
    private const int ALU_OP_TEST = 6;
    private const int ALU_OP_OR   = 7;
    private const int ALU_OP_XOR  = 8;
    private const int ALU_OP_SHL  = 9;
    private const int ALU_OP_SHR  = 10;
    private const int ALU_OP_ROL  = 11;
    private const int ALU_OP_ROR  = 12;
    private const int ALU_OP_MUL  = 15;

    private const int OPCODE_BR      = 0;
    private const int OPCODE_JMP     = 1;
    private const int OPCODE_MISC    = 2;
    private const int OPCODE_ALUOP   = 3;
    private const int OPCODE_CALL    = 4;
    private const int OPCODE_MOVI    = 5;
    private const int OPCODE_ALUOPI1 = 6;
    private const int OPCODE_ALUOPI2 = 7;

    private const int OPCODE7_HLT    = 0x20;
    private const int OPCODE7_WFI    = 0x21;
    private const int OPCODE7_MOVRR  = 0x22;
    private const int OPCODE7_RET    = 0x23;
    private const int OPCODE7_RETI   = 0x24;
    private const int OPCODE7_LOADSP = 0x25;
    private const int OPCODE7_PUSH   = 0x26;
    private const int OPCODE7_POP    = 0x27;
    private const int OPCODE7_MOVMR  = 0x28;
    private const int OPCODE7_MOVRM  = 0x29;
    private const int OPCODE7_IN     = 0x2A;
    private const int OPCODE7_OUT    = 0x2B;
    private const int OPCODE7_LOADPC = 0x2C;
    private const int OPCODE7_RCALL  = 0x2D;
    
    public bool InInterrupt { get; private set; }

    private ushort _acc, _acc2;
    
    public bool C { get; private set; }
    public bool Z => _acc == 0;
    public bool N => (_acc & 0x8000) != 0;
    
    public readonly ushort[] Registers;
    public readonly ushort[] Memory;
    
    public ushort Sp { get; private set; }

    private uint _savedPc;
    
    private static uint GetOpCode(uint instruction) => instruction >> 13;
    private static uint GetOpCode7(uint instruction) => instruction >> 9;
    
    private readonly bool _trace, _stopOnWfi;
    
    public Tiny16v6(string[] code, int speed, string[]? cpuOptions): base(code, speed, 0)
    {
        _trace = cpuOptions?.Contains("TRACE") ?? false;
        _stopOnWfi = cpuOptions?.Contains("STOP_ON_WFI") ?? false;
        var memoryStr = cpuOptions?.FirstOrDefault(op => op.StartsWith("MEMORY_SIZE=")) ?? "MEMORY_SIZE=4096";
        var memorySize = int.Parse(memoryStr[12..]);
        Registers = BuildUShortRegisters(16);
        Memory = BuildUShortRegisters(memorySize);
        var idx = 0;
        foreach (var c in Code)
            Memory[idx++] = (ushort)c.Instruction;
    }
    
    protected override uint? IsCall(uint instruction)
    {
        return (GetOpCode(instruction) == OPCODE_CALL) || (GetOpCode7(instruction) == OPCODE7_RCALL) ? (ushort)(Pc + 1) : null;
    }

    private void AddOffset13(uint instruction)
    {
        var offset13 = instruction & 0x1FFF;
        if ((offset13 & 0x1000) != 0)
            offset13 |= 0xFFFFF000;
        Pc = (uint)((int)Pc + (int)offset13);
    }

    private void AddOffset9(uint instruction)
    {
        var offset9 = (instruction >> 4) & 0x1FF;
        if ((offset9 & 0x100) != 0)
            offset9 |= 0xFFFFFF00;
        Pc = (uint)((int)Pc + (int)offset9);
    }

    private void RegisterDump()
    {
        Logger?.Info($"R0 ={Registers[0]:X4} R1 ={Registers[1]:X4} R2 ={Registers[2]:X4} R3 ={Registers[3]:X4}");
        Logger?.Info($"R4 ={Registers[4]:X4} R5 ={Registers[5]:X4} R6 ={Registers[6]:X4} R7 ={Registers[7]:X4}");
        Logger?.Info($"R8 ={Registers[8]:X4} R9 ={Registers[9]:X4} R10={Registers[10]:X4} R11={Registers[11]:X4}");
        Logger?.Info($"R12={Registers[12]:X4} R13={Registers[13]:X4} R14={Registers[14]:X4} R15={Registers[15]:X4}");
    }

    private void StepMisc(uint codeMisc, uint srcReg, uint dstReg)
    {
        IoEvent ev;

        switch (codeMisc)
        {
            case OPCODE7_HLT:
                Logger?.Info($"{Ticks}: HLT {Pc:X4}");
                RegisterDump();
                Hlt = true;
                Pc++;
                break;
            case OPCODE7_WFI:
                Logger?.Info($"{Ticks}: WFI {Pc:X4}");
                Wfi = true;
                Pc++;
                break;
            case OPCODE7_MOVRR:
                Registers[dstReg] = Registers[srcReg];
                Pc++;
                break;
            case OPCODE7_RET:
                Pc = Memory[Sp++];
                break;
            case OPCODE7_RETI:
                Pc = _savedPc;
                break;
            case OPCODE7_LOADSP:
                Sp = Registers[dstReg];
                Pc++;
                break;
            case OPCODE7_PUSH:
                Memory[--Sp] = Registers[srcReg];
                Pc++;
                break;
            case OPCODE7_POP:
                Registers[dstReg] = Memory[Sp++];
                Pc++;
                break;
            case OPCODE7_MOVMR:
                Registers[dstReg] = Memory[Registers[srcReg]];
                Pc++;
                break;
            case OPCODE7_MOVRM:
                Memory[Registers[dstReg]] = Registers[srcReg];
                Pc++;
                break;
            case OPCODE7_IN:
                if (IoReadEventHandler == null)
                    throw new CpuException("null IoReadEventHandler");
                ev = new IoEvent { Address = Registers[srcReg] };
                IoReadEventHandler(this, ev);
                Registers[dstReg] = (ushort)ev.Data;
                Pc++;
                break;
            case OPCODE7_OUT:
                if (IoWriteEventHandler == null)
                    throw new CpuException("null IoWriteEventHandler");
                ev = new IoEvent { Address = Registers[srcReg], Data = Registers[dstReg] };
                IoWriteEventHandler(this, ev);
                Pc++;
                break;
            case OPCODE7_LOADPC:
                Pc = Registers[dstReg];
                break;
            case OPCODE7_RCALL:
                Memory[--Sp] = (ushort)(Pc + 1);
                Pc = Registers[dstReg];
                break;
            default:
                SetError($"Unknown OpCode7 {codeMisc}");
                break;
        }
    }

    private void SetC(uint acc) => C = (acc & 0xFFFF0000) != 0;
    
    private void AluOperation(uint aluOp, uint data, uint dstReg)
    {
        uint acc;
        var dstRegData = (uint)Registers[dstReg];
        bool c = C;
        switch (aluOp)
        {
            case ALU_OP_ADC:
                acc = dstRegData + data;
                if (C)
                    acc++;
                SetC(acc);
                break; 
            case ALU_OP_ADD:
                acc = dstRegData + data;
                SetC(acc);
                break; 
            case ALU_OP_SBC:
                acc = dstRegData - data;
                if (C)
                    acc--;
                SetC(acc);
                break; 
            case ALU_OP_SUB:
            case ALU_OP_CMP:
                acc = dstRegData - data;
                SetC(acc);
                break; 
            case ALU_OP_AND:
            case ALU_OP_TEST:
                acc = dstRegData & data;
                break; 
            case ALU_OP_OR:
                acc = dstRegData | data;
                break;
            case ALU_OP_XOR:
                acc = dstRegData ^ data;
                break;
            case ALU_OP_SHL:
                C = (data & 0x8000) != 0;
                acc = data << 1;
                break;
            case ALU_OP_SHR:
                C = (data & 1) != 0;
                acc = data >> 1;
                break;
            case ALU_OP_ROL:
                C = (data & 0x8000) != 0;
                acc = data << 1;
                if (c)
                    acc |= 1;
                break;
            case ALU_OP_ROR:
                C = (data & 1) != 0;
                acc = data >> 1;
                if (c)
                    acc |= 0x8000;
                break;
            case ALU_OP_MUL:
                acc = dstRegData * data;
                _acc2 = (ushort)(acc >> 16);
                break;
            default:
                SetError($"Unknown Alu Operation {aluOp}");
                return;
        }
        _acc = (ushort)acc;
        if ((aluOp != ALU_OP_CMP) && (aluOp != ALU_OP_TEST))
            Registers[dstReg] = _acc;
        Pc++;
    }
    
    private void AluOp(uint aluOp, uint srcReg, uint dstReg)
    {
        AluOperation(aluOp, Registers[srcReg], dstReg);
    }

    private void AluOpi(uint aluOp, uint instruction, uint srcReg, uint dstReg)
    {
        var data = ((instruction >> 8) & 0x30) | srcReg;
        if ((data & 0x20) != 0)
            data |= 0xFFFFFFC0;
        AluOperation(aluOp, data, dstReg);
    }
    
    private bool ConditionMatch(uint condition)
    {
        var ok = C & (condition & 4) != 0;
        if (!ok)
            ok = Z & (condition & 2) != 0;
        if (!ok)
            ok = N & (condition & 1) != 0;
        if ((condition & 8) != 0)
            ok = !ok;
        return ok;
    }

    public override void Step()
    {
        base.Step();
        
        if (Hlt | Error)
            return;

        if (_trace)
            Logger?.Debug($"Step: {Pc:X4} Wfi={Wfi}");
        
        if (Interrupt != 0 && !InInterrupt)
        {
            InInterrupt = true;
            Wfi = false;
            _savedPc = Pc;
            Pc = 1;
        }
        
        if (Wfi)
            return;
        
        var instruction = (uint)Memory[Pc];

        var srcReg = (instruction & 0xF0) >> 4; 
        var dstReg = instruction & 0x0F;
        var aluOp = (instruction >> 8) & 0x0F;

        switch (GetOpCode(instruction))
        {
            case OPCODE_BR:
                if (ConditionMatch(dstReg))
                    AddOffset9(instruction);
                else
                    Pc++;
                break;
            case OPCODE_JMP:
                AddOffset13(instruction);
                break;
            case OPCODE_MISC:
                StepMisc(instruction >> 9, srcReg, dstReg);
                break;
            case OPCODE_ALUOP:
                AluOp(aluOp, srcReg, dstReg);
                break;
            case OPCODE_CALL:
                Memory[--Sp] = (ushort)(Pc + 1);
                AddOffset13(instruction);
                break;
            case OPCODE_MOVI:
                var addr = (instruction >> 4) & 0x1FF;
                Registers[dstReg] = Memory[addr];
                Pc++;
                break;
            case OPCODE_ALUOPI1:
            case OPCODE_ALUOPI2:
                AluOpi(aluOp, instruction, srcReg, dstReg);
                break;
            default:
                SetError("Unknown OpCode");
                break;
        }
    }

    private void SetError(string message)
    {
        Logger?.Error($"Step: {Pc:X4} {message}");
        Error = true;
    }

    public override void Run()
    {
        while (!Error & !Hlt & !(_stopOnWfi & Wfi) & !Breakpoints.Contains(Pc))
            Step();
    }
}