using System.Globalization;
using Cpu16EmulatorCommon;

namespace IODeviceBaseMemory32;

public sealed class IODeviceBaseMemory32: IIODevice
{
    private uint _startAddress, _endAddress;
    private uint[] _memory = [];
    private bool _readOnly;
    private ILogger? _logger;
    private uint _maxAddress;
    
    public object? Init(string parameters, ILogger logger)
    {
        var kv = IODeviceParametersParser.ParseParameters(parameters);
        _startAddress = IODeviceParametersParser.ParseUInt(kv, "address") ?? 
                        throw new IODeviceException("memory: missing or wrong address parameter");
        var size = IODeviceParametersParser.ParseUInt(kv, "size") ?? 
                        throw new IODeviceException("memory: missing or wrong size parameter");

        _logger = logger;
        
        _readOnly = kv.TryGetValue("readonly", out var readOnly) && readOnly == "true";

        _endAddress = _startAddress + size - 1;
        _maxAddress = _startAddress;
        _memory = new uint[size];

        var r = new Random();
        for (var i = 0; i < _memory.Length; i++)
            _memory[i] = (uint)r.Next();
        
        if (kv.TryGetValue("contents", out var fileName))
            Init(fileName);

        return null;
    }

    private void Init(string fileName)
    {
        var idx = 0;
        foreach (var line in File.ReadAllLines(fileName))
            _memory[idx++] = uint.Parse(line.Split("//")[0], NumberStyles.HexNumber);
    }

    public void IoRead(IoEvent ev)
    {
        if (ev.Address >= _startAddress && ev.Address <= _endAddress)
        {
            if (ev.Address > _maxAddress)
                _maxAddress = ev.Address;
            ev.Data = _memory[ev.Address - _startAddress];
        }
    }

    public void IoWrite(IoEvent ev)
    {
        if (ev.Address >= _startAddress && ev.Address <= _endAddress)
        {
            if (_readOnly)
                _logger?.Error($"Readonly memory write {ev.Address}");
            else
            {
                if (ev.Address > _maxAddress)
                    _maxAddress = ev.Address;
                _memory[ev.Address - _startAddress] = ev.Data;
            }
        }
    }

    public uint TicksUpdate(int cpuSped, int ticks, bool wfi, uint interruptAck, out uint clearMask)
    {
        clearMask = 0;
        return 0;
    }

    public void PrintStats()
    {
        Console.WriteLine($"MaxAddress = {_maxAddress:X8}");
    }
}