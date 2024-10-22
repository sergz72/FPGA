using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using Cpu16EmulatorCommon;

namespace Cpu16Emulator;

internal sealed class CpuException(string message) : Exception(message);

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
            throw new CpuException($"invalid code line: {line}");
        SourceCode = parts[1][6..].Replace("\t", "");
        Pc = pc;
    }

    public override string ToString()
    {
        return Pc.ToString("X4") + " " + SourceCode;
    }
}

public abstract class Cpu
{
    public readonly CodeLine[] Code;
    
    public readonly HashSet<ushort> Breakpoints = [];

    public ushort Pc { get; protected set; }
    public ushort Sp { get; protected set; }
    
    public readonly ushort[] Registers;

    public readonly int Speed;
    public int Ticks { get; private set; }

    protected readonly ushort StartPc;
    
    public bool Hlt { get; protected set; }

    public bool Error { get; protected set; }
    
    public uint Interrupt { get; set; }
    
    public bool InInterrupt { get; protected set; }
    
    public EventHandler<IoEvent>? IoWriteEventHandler;
    public EventHandler<IoEvent>? IoReadEventHandler;
    public EventHandler<int>? TicksEventHandler;
    
    public Cpu(string[] code, int speed, int registerCount, ushort startPc = 0)
    {
        Code = code.Select((c, i) => new CodeLine(c, (ushort)i)).ToArray();
        Registers = new ushort[registerCount];
        var r = new Random();
        for (var i = 0; i < Registers.Length; i++)
            Registers[i] = (ushort)r.Next(0xFFFF);
        Speed = speed;
        StartPc = startPc;
    }
    
    public virtual void Reset()
    {
        Ticks = 0;
        Pc = StartPc;
        Hlt = Error = InInterrupt = false;
        Interrupt = 0;
    }

    protected abstract ushort? IsCall(uint instruction);
    
    public virtual void StepOver()
    {
        if (Hlt | Error)
            return;

        var instruction = Code[Pc].Instruction;
        var nextPc = IsCall(instruction);
        if (nextPc != null)
        {
            do
            {
                Step();
            } while (Pc != nextPc && !Hlt && !Error);
        }
        else
            Step();
    }
    
    public virtual void Step()
    {
        Ticks++;
        if (TicksEventHandler == null)
            throw new CpuException("null TicksEventHandler");
        TicksEventHandler(this, Ticks);
    }

    public virtual void Run()
    {
        while (!Error & (Hlt | (!Hlt & !Breakpoints.Contains(Pc))))
            Step();
    }
    
    public virtual void Stop()
    {
        
    }
}

public interface ICpuView
{
    void Update();
}