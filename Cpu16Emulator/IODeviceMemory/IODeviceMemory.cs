using System.Globalization;
using Avalonia.Controls;
using Cpu16EmulatorCommon;

namespace IODeviceMemory;

public sealed class IODeviceMemory: IIODevice
{
    private ushort _startAddress, _endAddress;
    private ushort[] _memory = [];
    
    public Control? Init(string parameters, ILogger _)
    {
        var kv = IODeviceParametersParser.ParseParameters(parameters);
        _startAddress = IODeviceParametersParser.ParseUShort(kv, "address") ?? 
                        throw new IODeviceException("memory: missing or wrong address parameter");
        var length = IODeviceParametersParser.ParseUShort(kv, "length") ?? 
                        throw new IODeviceException("memory: missing or wrong length parameter");
        _endAddress = (ushort)(_startAddress + length - 1);
        _memory = new ushort[length];
        return null;
    }

    public void IoRead(IoEvent ev)
    {
        if (ev.Address >= _startAddress && ev.Address <= _endAddress)
            ev.Data = _memory[ev.Address - _startAddress];
    }

    public void IoWrite(IoEvent ev)
    {
        if (ev.Address >= _startAddress && ev.Address <= _endAddress)
            _memory[ev.Address - _startAddress] = ev.Data;
    }

    public bool? TicksUpdate(int cpuSped, int ticks)
    {
        return null;
    }
}