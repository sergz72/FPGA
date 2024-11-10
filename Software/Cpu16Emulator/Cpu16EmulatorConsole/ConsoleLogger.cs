using Cpu16EmulatorCommon;

namespace Cpu16EmulatorConsole;

public class ConsoleLogger: ILogger
{
    private readonly LogLevel _logLevel;
    private readonly StreamWriter? _logFile;
    
    internal ConsoleLogger(string? fileName, LogLevel logLevel)
    {
        _logFile = fileName != null ? new StreamWriter(fileName) : null;
        _logLevel = logLevel;
    }
    
    public void Debug(string message)
    {
        var formatted = $"DEBUG: {message}";
        if (_logLevel <= LogLevel.Debug)
            Console.WriteLine(formatted);
        _logFile?.WriteLine(formatted);
        _logFile?.Flush();
    }

    public void Info(string message)
    {
        var formatted = $"INFO: {message}";
        if (_logLevel <= LogLevel.Info)
            Console.WriteLine(formatted);
        _logFile?.WriteLine(formatted);
        _logFile?.Flush();
    }

    public void Warning(string message)
    {
        var formatted = $"WARNING: {message}";
        if (_logLevel <= LogLevel.Warning)
            Console.WriteLine(formatted);
        _logFile?.WriteLine(formatted);
        _logFile?.Flush();
    }

    public void Error(string message)
    {
        var formatted = $"ERROR: {message}";
        Console.WriteLine(formatted);
        _logFile?.WriteLine(formatted);
        _logFile?.Flush();
    }
}