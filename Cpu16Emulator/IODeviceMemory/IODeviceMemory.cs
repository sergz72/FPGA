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
        var size = IODeviceParametersParser.ParseUShort(kv, "size") ?? 
                        throw new IODeviceException("memory: missing or wrong size parameter");
        if (!kv.TryGetValue("control", out var control))
            throw new IODeviceException("IODeviceMemory: missing control parameter");

        _endAddress = (ushort)(_startAddress + size - 1);
        _memory = new ushort[size];

        if (control.StartsWith("LCD1,"))
            return LCD1.Create(_memory, control[5..]);
        
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