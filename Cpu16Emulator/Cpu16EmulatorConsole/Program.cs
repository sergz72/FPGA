using Cpu16EmulatorCommon;
using Cpu16EmulatorConsole;
using Cpu16EmulatorCpus;

var configurationFileNameExpected = false;
string? configurationFileName = null;
string? codeFileName = null;
int? limit = null;
var limitExpected = false;

foreach (var arg in args)
{
    if (configurationFileNameExpected)
    {
        configurationFileName = arg;
        configurationFileNameExpected = false;
        continue;
    }

    if (limitExpected)
    {
        limit = int.Parse(arg);
        limitExpected = false;
        continue;
    }

    switch (arg)
    {
        case "-c":
            configurationFileNameExpected = true;
            break;
        case "-l":
            limitExpected = true;
            break;
        default:
            if (codeFileName == null)
                codeFileName = arg;
            break;
    }
}

if (configurationFileNameExpected || limitExpected || configurationFileName == null || codeFileName == null)
{
    Usage();
    return;
}

var (cpu, devices, logFileName, logLevel) = Cpu.Load(configurationFileName, codeFileName);

var logger = new ConsoleLogger(logFileName, logLevel);
cpu.Logger = logger;

foreach (var d in devices)
    d.Device.Init(d.Parameters, logger);

var ioDevices = new IODevices(cpu, devices, logger);
cpu.IoReadEventHandler = ioDevices.IoRead;
cpu.IoWriteEventHandler = ioDevices.IoWrite;
cpu.TicksEventHandler = ioDevices.TicksUpdate;

if (limit != null)
{
    while (cpu.Ticks < limit)
        cpu.Step();
}
else
    cpu.Run();

return;

void Usage()
{
    Console.WriteLine("Usage: Cpu16EmulatorConsole -c configFilename codeFileName [dataFileName] [roDataFileName]");
}

