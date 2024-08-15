using Avalonia.Controls;

namespace Cpu16EmulatorCommon;

public interface IIODevice
{
    Control? Init(string parameters);
    void IoRead(IoEvent ev);
    void IoWrite(IoEvent ev);
    bool? TicksUpdate(int cpuSped, int ticks);
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
}

public sealed class IoEvent
{
    public ushort Address;
    public ushort Data;
}

public class IODeviceException(string message): Exception(message)
{}