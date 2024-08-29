using System.Globalization;
using Avalonia.Controls;
using Cpu16EmulatorCommon;

namespace IODeviceMemory;

public sealed class IODeviceMemory: IIODevice
{
    private ushort _startAddress, _endAddress;
    private ushort[] _memory = [];
    private bool _readOnly;
    private ILogger? _logger;
    private Control? _control;
    
    public Control? Init(string parameters, ILogger logger)
    {
        var kv = IODeviceParametersParser.ParseParameters(parameters);
        _startAddress = IODeviceParametersParser.ParseUShort(kv, "address") ?? 
                        throw new IODeviceException("memory: missing or wrong address parameter");
        var size = IODeviceParametersParser.ParseUShort(kv, "size") ?? 
                        throw new IODeviceException("memory: missing or wrong size parameter");
        if (!kv.TryGetValue("control", out var control))
            throw new IODeviceException("IODeviceMemory: missing control parameter");

        _logger = logger;
        
        _readOnly = kv.TryGetValue("readonly", out var readOnly) && readOnly == "true";

        _endAddress = (ushort)(_startAddress + size - 1);
        _memory = new ushort[size];

        var r = new Random();
        for (var i = 0; i < _memory.Length; i++)
            _memory[i] = (ushort)r.Next(ushort.MaxValue);
        
        if (kv.TryGetValue("contents", out var fileName))
            Init(fileName);

        if (control.StartsWith("LCD1,"))
            _control = LCD1.Create(_memory, control[5..]);
        else
            _control = null;

        return _control;
    }

    private void Init(string fileName)
    {
        var idx = 0;
        foreach (var line in File.ReadAllLines(fileName))
            _memory[idx++] = ushort.Parse(line.Split("//")[0], NumberStyles.HexNumber);
    }

    public void IoRead(IoEvent ev)
    {
        if (ev.Address >= _startAddress && ev.Address <= _endAddress)
            ev.Data = _memory[ev.Address - _startAddress];
    }

    public void IoWrite(IoEvent ev)
    {
        if (ev.Address >= _startAddress && ev.Address <= _endAddress)
        {
            if (_readOnly)
                _logger?.Error($"Readonly memory write {ev.Address}");
            else
            {
                _memory[ev.Address - _startAddress] = ev.Data;
                _control?.InvalidateVisual();
            }
        }
    }

    public bool? TicksUpdate(int cpuSped, int ticks)
    {
        return null;
    }
}