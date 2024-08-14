using System;
using System.Globalization;
using System.Linq;

namespace Cpu16Emulator;

public sealed class Cpu16
{
    internal sealed class Cpu16Exception(string message): Exception(message)
    {}

    public sealed class IoEvent
    {
        public ushort Address;
        public ushort Data;
    }
    
    public sealed class CodeLine
    {
        public readonly uint Pc;
        public readonly uint Instruction;
        public readonly string SourceCode;
        
        internal CodeLine(string line, uint pc)
        {
            var parts = line.Split("//");
            if (parts.Length != 2 || !uint.TryParse(parts[0], NumberStyles.HexNumber, null, out Instruction)
                || parts[1][0] != ' ' || !char.IsAsciiHexDigit(parts[1][1]) || !char.IsAsciiHexDigit(parts[1][2]) ||
                !char.IsAsciiHexDigit(parts[1][3]) || !char.IsAsciiHexDigit(parts[1][4]) || parts[1][5] != ' ')
                throw new Cpu16Exception($"invalid code line: {line}");
            SourceCode = parts[1][6..].Replace("\t", "");
            Pc = pc;
        }

        public override string ToString()
        {
            return Pc.ToString("X4") + " " + SourceCode;
        }
    }
    
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
    private const int ALU_OP_MUL = 12;
    private const int ALU_OP_DIV = 13;
    private const int ALU_OP_REM = 14;
    private const int ALU_OP_SETF = 15;
    
    public readonly CodeLine[] Code;
    public ushort Pc { get; private set; }
    public ushort Sp { get; private set; }

    public ushort AluOut { get; private set; }
    public ushort AluOut2 { get; private set; }
    
    public readonly ushort[] Registers;
    public readonly ushort[] Stack;
    public bool Hlt { get; private set; }
    public bool Error { get; private set; }
    
    public bool C { get; private set; }
    public bool Z { get; private set; }
    public bool N { get; private set; }
    
    private bool _interrupt;
    public bool Interrupt
    {
        get => _interrupt;
        set {
            _interrupt = value;
            if (value)
                Hlt = false;
        }
    }

    public EventHandler<IoEvent> IoWriteEventHandler;
    public EventHandler<IoEvent> IoReadEventHandler;
    
    public Cpu16(string[] code, int stackSize)
    {
        Code = code.Select((c, i) => new CodeLine(c, (ushort)i)).ToArray();
        Registers = new ushort[256];
        Stack = new ushort[stackSize];
        var r = new Random();
        for (var i = 0; i < Registers.Length; i++)
            Registers[i] = (ushort)r.Next(0xFFFF);
        for (var i = 0; i < Stack.Length; i++)
            Stack[i] = (ushort)r.Next(0xFFFF);
        Reset();
    }

    public void StepOver()
    {
        if (Hlt | Error)
            return;

        var instruction = Code[Pc].Instruction;
        var opType = (instruction >> 4) & 0x0F;
        if (opType is 2 or 3) // call
        {

            var nextPc = Pc + 1;
            do
            {
                Step();
            } while (Pc != nextPc && !Hlt);
        }
        else
            Step();
    }
    public void Step()
    {
        if (Hlt | Error)
            return;
        
        var instruction = Code[Pc].Instruction;
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
                    Pc = (ushort)(instruction >> 16);
                break;
            case 1: // jmp reg
                if (!ConditionMatch(opSubtype))
                    Pc = (ushort)(Pc + 1);
                else
                    Pc = (ushort)(Registers[regNo2] + adder);
                break;
            case 2: // call addr
                if (!ConditionMatch(opSubtype))
                    Pc = (ushort)(Pc + 1);
                else
                    Call((ushort)(instruction >> 16));
                break;
            case 3: // call reg
                if (!ConditionMatch(opSubtype))
                    Pc = (ushort)(Pc + 1);
                else
                    Call((ushort)(Registers[regNo2] + adder));
                break;
            case 4: // ret
                if (!ConditionMatch(instruction))
                    Pc = (ushort)(Pc + 1);
                else
                    Ret();
                break;
            case 5:
                switch (opSubtype)
                {
                    // reti
                    case <= 6:
                        if (!ConditionMatch(instruction))
                            Pc = (ushort)(Pc + 1);
                        else
                            Ret();
                        break;
                    case 0x0A: // mov reg alu_out_2
                        Registers[regNo1] = AluOut2;
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
                Registers[regNo1] = AluOperation(instruction & 0x1F, Registers[regNo2], Registers[regNo3], Registers[regNo1]);
                break;
            case 8: // alu instruction, register->register
            case 9:
                Registers[regNo1] = AluOperation(instruction & 0x1F, Registers[regNo2], immediate, Registers[regNo1]);
                break;
            default:
                Hlt = Error = true;
                break;
        }
    }

    private ushort AluOperation(uint opId, ushort op1, ushort op2, ushort op3)
    {
        AluOut = opId switch
        {
            ALU_OP_TEST:
            _ => AluOut
        };
        return AluOut;
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
        Pc = Stack[Sp];
        if (Sp == Stack.Length - 1)
            Sp = 0;
        else
            Sp++;
    }
    
    private void Call(ushort address)
    {
        if (Sp == 0)
            Sp = (ushort)(Stack.Length - 1);
        else
            Sp--;
        Stack[Sp] = (ushort)(Pc + 1);
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
            default:
                Hlt = Error = true;
                break;
        }
        return false;
    }

    public void Run()
    {
        
    }

    public void Stop()
    {
        
    }

    public void Reset()
    {
        Pc = Sp = 0;
        Hlt = Error = _interrupt = false;
    }
}