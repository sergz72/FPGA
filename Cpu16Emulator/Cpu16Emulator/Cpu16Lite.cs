using Cpu16EmulatorCommon;

namespace Cpu16Emulator;

public sealed class Cpu16Lite(string[] code, int speed): Cpu(code, speed, 256)
{
    private const int ALU_OP_TEST = 0;
    private const int ALU_OP_NEG = 1;
    private const int ALU_OP_ADD = 2;
    private const int ALU_OP_ADC = 3;
    private const int ALU_OP_SUB = 4;
    private const int ALU_OP_SBC = 5;
    private const int ALU_OP_SHL = 6;
    private const int ALU_OP_SHR = 7;
    private const int ALU_OP_AND = 8;
    private const int ALU_OP_OR  = 9;
    private const int ALU_OP_XOR = 10;
    private const int ALU_OP_CMP = 11;
    private const int ALU_OP_SETF = 12;
    private const int ALU_OP_RLC = 13;
    private const int ALU_OP_RRC = 14;
    private const int ALU_OP_SHLC = 15;
    private const int ALU_OP_SHRC = 16;

    public ushort Rp { get; private set; }

    public ushort AluOut { get; private set; }
    
    public bool C { get; private set; }
    public bool Z { get; private set; }
    public bool N { get; private set; }
    
    protected override ushort? IsCall(uint instruction)
    {
        var opType = (instruction >> 4) & 0x0F;
        return opType is 2 or 3 ? (ushort)(Pc + 1) : null;
    }
    
    public override void Step()
    {
        base.Step();
        
        if (Error)
            return;

        var instruction = Code[Pc].Instruction;

        if (Interrupt != 0 && !InInterrupt)
        {
            InInterrupt = true;
            Hlt = false;
            instruction = 0x00010020; // call 1
            Pc--;
        }
        
        if (Hlt)
            return;
        
        var opType = (instruction >> 4) & 0x0F;
        var opSubtype = instruction & 0x0F;
        var regNo1 = (instruction >> 8) & 0xFF;
        var regNo2 = (instruction >> 16) & 0xFF;
        var regNo3 = instruction >> 24;
        var adder = (ushort)regNo3;
        var immediate = (ushort)(instruction >> 16);
        switch (opType)
        {
            case 0: // jmp addr
                if (!ConditionMatch(opSubtype))
                    Pc = (ushort)(Pc + 1);
                else
                    Pc = immediate;
                break;
            case 1: // jmp reg
                if (!ConditionMatch(opSubtype))
                    Pc = (ushort)(Pc + 1);
                else
                    Pc = (ushort)(Registers[regNo1] + immediate);
                break;
            case 2: // call addr
                if (!ConditionMatch(opSubtype))
                    Pc = (ushort)(Pc + 1);
                else
                    Call(immediate);
                break;
            case 3: // call reg
                if (!ConditionMatch(opSubtype))
                    Pc = (ushort)(Pc + 1);
                else
                    Call((ushort)(Registers[regNo1] + immediate));
                break;
            case 4: // ret
                if (!ConditionMatch(opSubtype))
                    Pc = (ushort)(Pc + 1);
                else
                    Ret();
                break;
            case 5:
                switch (opSubtype)
                {
                    // reti
                    case <= 6:
                        if (!ConditionMatch(opSubtype))
                            Pc = (ushort)(Pc + 1);
                        else
                        {
                            Ret();
                            InInterrupt = false;
                        }
                        break;
                    case 0x08: // inc rp
                        IncRp();
                        Pc = (ushort)(Pc + 1);
                        break;
                    case 0x09: // dec rp
                        DecRp();
                        Pc = (ushort)(Pc + 1);
                        break;
                    case 0x0A: // load rp
                        Rp = adder;
                        Pc = (ushort)(Pc + 1);
                        break;
                    case 0x0B: // mov flags to register
                        Registers[regNo1] = BuildFlags();
                        Pc = (ushort)(Pc + 1);
                        break;
                    case 0x0C: // nop
                        Pc = (ushort)(Pc + 1);
                        break;
                    case 0x0D: // mov reg immediate
                        Registers[regNo1] = immediate;
                        Pc = (ushort)(Pc + 1);
                        break;
                    case 0x0E: // mov reg reg
                        Registers[regNo1] = (ushort)(Registers[regNo2] + adder);
                        Pc = (ushort)(Pc + 1);
                        break;
                    case 0x0F:
                        Hlt = true;
                        Pc = (ushort)(Pc + 1);
                        break;
                    default:
                        Hlt = Error = true;
                        break;
                }
                break;
            case 6: // alu instruction, register->register
            case 7:
                AluOperation(instruction & 0x1F, regNo1, Registers[regNo2], Registers[regNo3]);
                Pc = (ushort)(Pc + 1);
                break;
            case 8: // alu instruction, immediate->register
            case 9:
                AluOperation(instruction & 0x1F, regNo1, Registers[regNo1], immediate);
                Pc = (ushort)(Pc + 1);
                break;
            case 14: // mov with rp
                switch (opSubtype)
                {
                    case 0:
                        Registers[Rp] = immediate;
                        Pc = (ushort)(Pc + 1);
                        break;
                    case 1:
                        Registers[Rp] = immediate;
                        IncRp();
                        Pc = (ushort)(Pc + 1);
                        break;
                    case 2:
                        DecRp();
                        Registers[Rp] = immediate;
                        Pc = (ushort)(Pc + 1);
                        break;
                    case 4:
                        Registers[Rp] = (ushort)(Registers[regNo1] + immediate);
                        Pc = (ushort)(Pc + 1);
                        break;
                    case 5:
                        Registers[Rp] = (ushort)(Registers[regNo1] + immediate);
                        IncRp();
                        Pc = (ushort)(Pc + 1);
                        break;
                    case 6:
                        DecRp();
                        Registers[Rp] = (ushort)(Registers[regNo1] + immediate);
                        Pc = (ushort)(Pc + 1);
                        break;
                    case 8:
                        Registers[regNo1] = (ushort)(Registers[Rp] + immediate);
                        Pc = (ushort)(Pc + 1);
                        break;
                    case 9:
                        Registers[regNo1] = (ushort)(Registers[Rp] + immediate);
                        IncRp();
                        Pc = (ushort)(Pc + 1);
                        break;
                    case 10:
                        DecRp();
                        Registers[regNo1] = (ushort)(Registers[Rp] + immediate);
                        Pc = (ushort)(Pc + 1);
                        break;
                    default:
                        Hlt = Error = true;
                        break;
                }
                break;
            case 15: // operations without ALU with io
                var ioAddress = (ushort)(Registers[regNo2] + adder);
                IoEvent ev;
                switch (opSubtype)
                {
                    case 0: //in io->register
                        if (IoReadEventHandler == null)
                            throw new CpuException("null IoReadEventHandler");
                        ev = new IoEvent { Address = ioAddress };
                        IoReadEventHandler(this, ev);
                        Registers[regNo1] = ev.Data;
                        Pc = (ushort)(Pc + 1);
                        break;
                    case 1: //in io->@rp
                        if (IoReadEventHandler == null)
                            throw new CpuException("null IoReadEventHandler");
                        ev = new IoEvent { Address = ioAddress };
                        IoReadEventHandler(this, ev);
                        Registers[Rp] = ev.Data;
                        Pc = (ushort)(Pc + 1);
                        break;
                    case 2: //in io->@rp++
                        if (IoReadEventHandler == null)
                            throw new CpuException("null IoReadEventHandler");
                        ev = new IoEvent { Address = ioAddress };
                        IoReadEventHandler(this, ev);
                        Registers[Rp] = ev.Data;
                        IncRp();
                        Pc = (ushort)(Pc + 1);
                        break;
                    case 3: //in io->@--rp
                        if (IoReadEventHandler == null)
                            throw new CpuException("null IoReadEventHandler");
                        ev = new IoEvent { Address = ioAddress };
                        IoReadEventHandler(this, ev);
                        DecRp();
                        Registers[Rp] = ev.Data;
                        Pc = (ushort)(Pc + 1);
                        break;
                    case 4: //out register->io
                        if (IoWriteEventHandler == null)
                            throw new CpuException("null IoWriteEventHandler");
                        ev = new IoEvent { Address = ioAddress, Data = Registers[regNo1] };
                        IoWriteEventHandler(this, ev);
                        Pc = (ushort)(Pc + 1);
                        break;
                    case 5: //out @rp->io
                        if (IoWriteEventHandler == null)
                            throw new CpuException("null IoWriteEventHandler");
                        ev = new IoEvent { Address = ioAddress, Data = Registers[Rp] };
                        IoWriteEventHandler(this, ev);
                        Pc = (ushort)(Pc + 1);
                        break;
                    case 6: //out @rp++->io
                        if (IoWriteEventHandler == null)
                            throw new CpuException("null IoWriteEventHandler");
                        ev = new IoEvent { Address = ioAddress, Data = Registers[Rp] };
                        IoWriteEventHandler(this, ev);
                        IncRp();
                        Pc = (ushort)(Pc + 1);
                        break;
                    case 7: //out @--rp->io
                        if (IoWriteEventHandler == null)
                            throw new CpuException("null IoWriteEventHandler");
                        DecRp();
                        ev = new IoEvent { Address = ioAddress, Data = Registers[Rp] };
                        IoWriteEventHandler(this, ev);
                        Pc = (ushort)(Pc + 1);
                        break;
                    default:
                        Hlt = Error = true;
                        break;
                }
                break;
            default:
                Hlt = Error = true;
                break;
        }
    }

    private void AluOperation(uint opId, uint regNo1, ushort op2, ushort op3)
    {
        int v;
        bool savedc;
        switch (opId)
        {
            case ALU_OP_TEST:
                AluOut = (ushort)(op2 & op3);
                break;
            case ALU_OP_AND:
                AluOut = (ushort)(op2 & op3);
                break;
            case ALU_OP_OR:
                AluOut = (ushort)(op2 | op3);
                break;
            case ALU_OP_ADD:
                v = op2 + op3;
                C = (v & 0xFFFF0000) != 0;
                AluOut = (ushort)v;
                break;
            case ALU_OP_SUB:
                v = op2 - op3;
                C = (v & 0xFFFF0000) != 0;
                AluOut = (ushort)v;
                break;
            case ALU_OP_ADC:
                v = op2 + op3 + (C ? 1: 0);
                C = (v & 0xFFFF0000) != 0;
                AluOut = (ushort)v;
                break;
            case ALU_OP_SBC:
                v = op2 - op3 - (C ? 1: 0);
                C = (v & 0xFFFF0000) != 0;
                AluOut = (ushort)v;
                break;
            case ALU_OP_CMP:
                v = op2 - op3;
                C = (v & 0xFFFF0000) != 0;
                AluOut = (ushort)v;
                break;
            case ALU_OP_NEG:
                AluOut = (ushort)(-(short)op2);
                break;
            case ALU_OP_SHL:
                AluOut = (ushort)(op2 << op3);
                break;
            case ALU_OP_SHR:
                AluOut = (ushort)(op2 >> op3);
                break;
            case ALU_OP_XOR:
                AluOut = (ushort)(op2 ^ op3);
                break;
            case ALU_OP_SETF:
                C = (op2 & 4) != 0;
                Z = (op2 & 2) != 0;
                N = (op2 & 1) != 0;
                break;
            case ALU_OP_RLC:
                savedc = C;
                C = (op2 & 0x8000) != 0;
                AluOut = (ushort)(op2 << 1);
                if (savedc)
                    AluOut |= 1;
                break;
            case ALU_OP_RRC:
                savedc = C;
                C = (op2 & 1) != 0;
                AluOut = (ushort)(op2 >> 1);
                if (savedc)
                    AluOut |= 0x8000;
                break;
            case ALU_OP_SHLC:
                C = (op2 & 0x8000) != 0;
                AluOut = (ushort)(op2 << 1);
                break;
            case ALU_OP_SHRC:
                C = (op2 & 1) != 0;
                AluOut = (ushort)(op2 >> 1);
                break;
        }
        Z = AluOut == 0;
        N = (AluOut & 0x8000) != 0;
        if (opId != ALU_OP_TEST && opId != ALU_OP_CMP && opId != ALU_OP_SETF)
            Registers[regNo1] = AluOut;
    }

    private ushort BuildFlags()
    {
        var flags = C ? 4 : 0;
        if (Z)
            flags |= 2;
        if (N)
            flags |= 1;
        return (ushort)flags;
    }

    private void Ret()
    {
        Pc = Registers[Sp];
        if (Sp == Registers.Length - 1)
            Sp = 0;
        else
            Sp++;
    }
    
    private void Call(ushort address)
    {
        if (Sp == 0)
            Sp = (ushort)(Registers.Length - 1);
        else
            Sp--;
        Registers[Sp] = (ushort)(Pc + 1);
        Pc = address;
    }
    
    private bool ConditionMatch(uint opSubType)
    {
        switch (opSubType)
        {
            case 0: return true;
            case 1: return C;
            case 2: return !C;
            case 3: return Z;
            case 4: return !Z;
            case 5: return !C & !Z;
            case 6: return Z | C;
            case 7: return N;
            case 8: return !N;
            default:
                Hlt = Error = true;
                break;
        }
        return false;
    }

    private void IncRp()
    {
        if (Rp == 255)
            Rp = 0;
        else
            Rp++;
    }

    private void DecRp()
    {
        if (Rp == 0)
            Rp = 255;
        else
            Rp--;
    }
    
    public override void Reset()
    {
        base.Reset();
        Rp = 0;
    }
}