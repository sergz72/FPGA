using System.Globalization;
using Avalonia.Controls;
using Cpu16EmulatorCommon;

namespace IODeviceFrequencyCounter;

public class IODeviceFrequencyCounter: IIODevice
{
    private int _value;
    private ushort _address;
    private int _interrupt;
    private ILogger? _logger;
    
    public Control? Init(string parameters, ILogger logger)
    {
        var kv = IODeviceParametersParser.ParseParameters(parameters);
        _address = IODeviceParametersParser.ParseUShort(kv, "address") ?? 
                   throw new IODeviceException("frequencyCounter: missing or wrong address parameter");
        if (!kv.TryGetValue("value", out var sValue) ||
            !int.TryParse(sValue, out _value))
            throw new IODeviceException("frequencyCounter: missing or wrong value parameter");
        _interrupt = 0;
        _logger = logger;
        return null;
    }

    public void IoRead(IoEvent ev)
    {
        if ((ushort)(ev.Address & 0xFFFE) == _address)
        {
            ev.Data = (ev.Address & 1) == 0 ? (ushort)(_value & 0xFFFF) : (ushort)((_value >> 16) | _interrupt);
            if (ev.Address == _address)
                _interrupt = 0;
        }
    }

    public void IoWrite(IoEvent ev)
    {
        if ((ushort)(ev.Address & 0xFFFE) == _address)
            _logger?.Error("Frequency counter io write");
    }

    public uint? TicksUpdate(int cpuSpeed, int ticks)
    {
        if ((ticks % cpuSpeed) == 0)
            _interrupt = 0x8000;
        return null;
    }
}