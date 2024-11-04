using Cpu16EmulatorCommon;

namespace Cpu16EmulatorConsole;

public class ConsoleLogger: ILogger
{
    private LogLevel _logLevel = LogLevel.Debug;
    
    public void SetLevel(LogLevel level)
    {
        _logLevel = level;
    }

    public void Debug(string message)
    {
        if (_logLevel <= LogLevel.Debug)
            Console.WriteLine($"DEBUG: {message}");
    }

    public void Info(string message)
    {
        if (_logLevel <= LogLevel.Info)
            Console.WriteLine($"INFO: {message}");
    }

    public void Warning(string message)
    {
        if (_logLevel <= LogLevel.Warning)
            Console.WriteLine($"WARNING: {message}");
    }

    public void Error(string message)
    {
        Console.WriteLine($"ERROR: {message}");
    }
}