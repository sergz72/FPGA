using System.Globalization;
using Avalonia.Controls;
using Cpu16EmulatorCommon;

namespace IODeviceFrequencyCounter;

public class IODeviceFrequencyCounter: IIODevice
{
    private int _value;
    private ushort _address;
    
    public Control? Init(string parameters, ILogger logger)
    {
        var kv = IODeviceParametersParser.ParseParameters(parameters);
        _address = IODeviceParametersParser.ParseUShort(kv, "address") ?? 
                   throw new IODeviceException("frequencyCounter: missing or wrong address parameter");
        if (!kv.TryGetValue("value", out var sValue) ||
            !int.TryParse(sValue, out _value))
            throw new IODeviceException("frequencyCounter: missing or wrong value parameter");
        return null;
    }

    public void IoRead(IoEvent ev)
    {
        if ((ushort)(ev.Address & 0xFFFE) == _address)
        {
            ev.Data = (ev.Address & 1) == 0 ? (ushort)(_value & 0xFFFF) : (ushort)(_value >> 16);
            ev.Interrupt = false;
        }
    }

    public void IoWrite(IoEvent ev)
    {
    }

    public bool? TicksUpdate(int cpuSpeed, int ticks)
    {
        return ticks % cpuSpeed == 0 ? true : null;
    }
}