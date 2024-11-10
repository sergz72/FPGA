using System.Globalization;

namespace Cpu16EmulatorCommon;

public enum LogLevel
{
    Debug,
    Info,
    Warning,
    Error
}
public interface ILogger
{
    void Debug(string message);
    void Info(string message);
    void Warning(string message);
    void Error(string message);
}

public interface IIODevice
{
    object? Init(string parameters, ILogger logger);
    void IoRead(IoEvent ev);
    void IoWrite(IoEvent ev);
    uint TicksUpdate(int cpuSped, int ticks, bool wfi, uint interruptAck, out uint interruptClearMask);
}

public static class IODeviceParametersParser
{
    public static Dictionary<string, string> ParseParameters(string parameters)
    {
        var result = new Dictionary<string, string>();
        var parts = parameters.Split(' ');
        foreach (var part in parts)
        {
            var nameValue = part.Split('=');
            if (nameValue.Length != 2)
                throw new IODeviceException($"invalid parameters string: {parameters}");
            result.Add(nameValue[0].Trim(), nameValue[1].Trim());
        }

        return result;
    }

    public static ushort? ParseUShort(Dictionary<string, string> kv, string parameterName)
    {
        if (!kv.TryGetValue(parameterName, out var sValue))
            return null;
        return ParseUShort(sValue);
    }

    public static ushort? ParseUShort(string sValue)
    {
        if (sValue.StartsWith("0x"))
        {
            if (!ushort.TryParse(sValue[2..], NumberStyles.AllowHexSpecifier, null, out var hValue))
                return null;
            return hValue;
        }
        if (!ushort.TryParse(sValue, out var value))
            return null;
        return value;
    }
}

public sealed class IoEvent
{
    public ushort Address;
    public ushort Data;
    public uint? InterruptClearMask;
}

public sealed class IODeviceException(string message): Exception(message);
