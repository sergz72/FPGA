using System.Globalization;
using Avalonia.Controls;
using Cpu16EmulatorCommon;

namespace IODeviceMemory;

public sealed class IODeviceMemory: IIODevice
{
    private ushort _startAddress, _endAddress;
    private ushort[] _memory = [];
    
    public Control? Init(string parameters)
    {
        var kv = IODeviceParametersParser.ParseParameters(parameters);
        if (!kv.TryGetValue("address", out var sAddress) ||
            !ushort.TryParse(sAddress, NumberStyles.AllowHexSpecifier, null, out _startAddress))
            throw new IODeviceException("missing or wrong address in parameters string");
        if (!kv.TryGetValue("length", out var sLength) ||
            !ushort.TryParse(sLength, NumberStyles.AllowHexSpecifier, null, out var length))
            throw new IODeviceException("missing or wrong length in parameters string");
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