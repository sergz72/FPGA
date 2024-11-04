using Cpu16EmulatorCommon;

namespace Cpu16EmulatorConsole;

public class ConsoleLogger: ILogger
{
    private LogLevel _logLevel = LogLevel.Debug;
    private StreamWriter? _logFile;
    
    public void SetLevel(LogLevel level)
    {
        _logLevel = level;
    }

    internal void SetFileName(string fileName)
    {
        _logFile = fileName != "" ? new StreamWriter(fileName) : null;
    }
    
    public void Debug(string message)
    {
        var formatted = $"DEBUG: {message}";
        if (_logLevel <= LogLevel.Debug)
            Console.WriteLine(formatted);
        _logFile?.WriteLine(formatted);
    }

    public void Info(string message)
    {
        var formatted = $"INFO: {message}";
        if (_logLevel <= LogLevel.Info)
            Console.WriteLine(formatted);
        _logFile?.WriteLine(formatted);
    }

    public void Warning(string message)
    {
        var formatted = $"WARNING: {message}";
        if (_logLevel <= LogLevel.Warning)
            Console.WriteLine(formatted);
        _logFile?.WriteLine(formatted);
    }

    public void Error(string message)
    {
        var formatted = $"ERROR: {message}";
        Console.WriteLine(formatted);
        _logFile?.WriteLine(formatted);
    }
}