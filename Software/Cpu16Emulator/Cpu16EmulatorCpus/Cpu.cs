using System.Globalization;
using System.Numerics;
using System.Reflection;
using System.Text.Json;
using Cpu16EmulatorCommon;

namespace Cpu16EmulatorCpus;

internal sealed class CpuException(string message) : Exception(message);

public sealed class CodeLine
{
    public readonly uint Pc;
    public readonly uint Instruction;
    public readonly string SourceCode;
    
    internal CodeLine(string line, uint pc)
    {
        var parts = line.Split("//");
        if (parts.Length != 2 || !uint.TryParse(parts[0], NumberStyles.HexNumber, null, out Instruction))
            throw new CpuException($"invalid code line: {line}");
        var pcAndCode = parts[1].Split(' ', 2, StringSplitOptions.RemoveEmptyEntries);
        if (!uint.TryParse(pcAndCode[0], NumberStyles.HexNumber, null, out _))
            throw new CpuException($"invalid code line: {line}");
        SourceCode = pcAndCode.Length == 2 ? pcAndCode[1].Trim() : "";
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
    
    public readonly HashSet<uint> Breakpoints = [];

    public uint Pc { get; protected set; }
    public uint Sp { get; protected set; }
    
    public readonly int Speed;
    public int Ticks { get; private set; }

    protected readonly uint StartPc;
    
    public bool Hlt { get; protected set; }

    public bool Error { get; protected set; }
    
    public bool Wfi { get; protected set; }
    
    public uint Interrupt { get; set; }
    
    public ILogger? Logger { get; set; }
    
    public EventHandler<IoEvent>? IoWriteEventHandler;
    public EventHandler<IoEvent>? IoReadEventHandler;
    public EventHandler<int>? TicksEventHandler;

    public Cpu(string[] code, int speed, uint startPc = 0)
    {
        Code = code.Select((c, i) => new CodeLine(c, (ushort)i)).ToArray();
        Speed = speed;
        StartPc = startPc;
    }
    
    public virtual void Reset()
    {
        Ticks = 0;
        Pc = StartPc;
        Hlt = Error = Wfi = false;
        Interrupt = 0;
    }

    protected abstract uint? IsCall(uint instruction);
    
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

    public virtual void Finish()
    {
        
    }
    
    public static (Cpu, IODevice[], string?, LogLevel) Load(string configurationFileName, string codeFileName)
    {
        var stream = File.OpenRead(configurationFileName);
        var config = JsonSerializer.Deserialize<Configuration>(stream);
        if (config == null || config.CpuSpeed == 0 || config.Cpu == "")
            throw new Exception("incorrect configuration file");
        var code = File.ReadAllLines(codeFileName);
        Cpu cpu = config.Cpu switch
        {
            "Cpu16Lite" => new Cpu16Lite(code, config.CpuSpeed * 1000),
            "Tiny16v4" => new Tiny16v4(code, config.CpuSpeed * 1000),
            "ForthCPU" => new ForthCPU(code, config.CpuSpeed * 1000, 256, 256, 16,
                                        config.CpuOptions),
            "JavaCPU" => new JavaCPU(code, config.CpuSpeed * 1000, 256, 256, config.CpuOptions),
            _ => throw new CpuException("invalid cpu")
        };
        var ioDevices = LoadIODevices(config.IODevices);
        cpu.Reset();
        return (cpu, ioDevices, config.LogFile, ParseLogLevel(config.LogLevel));
    }

    private static LogLevel ParseLogLevel(string? logLevel)
    {
        return logLevel switch
        {
            "Info" => LogLevel.Info,
            "Warning" => LogLevel.Warning,
            "Error" => LogLevel.Error,
            _ => LogLevel.Debug
        };
    }

    private static IODevice[] LoadIODevices(IODeviceFile[] deviceFiles)
    {
        return deviceFiles.SelectMany(LoadIODevices).ToArray();
    }
    
    private static IODevice[] LoadIODevices(IODeviceFile deviceFile)
    {
        var assembly = Assembly.LoadFile(Path.GetFullPath(deviceFile.FileName));
        return assembly.GetExportedTypes()
            .Where(t => typeof(IIODevice).IsAssignableFrom(t))
            .Select(t => new IODevice {
                Device = (IIODevice)(Activator.CreateInstance(t) ?? throw new IODeviceException($"cannot create instance for type {t.Name}")),
                Parameters = deviceFile.Parameters
            })
            .ToArray();
    }

    protected static ushort[] BuildUShortRegisters(int count)
    {
        var registers = new ushort[count];
        var r = new Random();
        for (var i = 0; i < count; i++)
            registers[i] = (ushort)r.Next(0xFFFF);
        return registers;
    }
}
