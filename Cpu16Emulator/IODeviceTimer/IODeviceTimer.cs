using Cpu16EmulatorCommon;

namespace IODeviceTimer;

public class IODeviceTimer: IIODevice
{
    private int _maxValue, _counter;
    private ushort _address;
    private uint _interrupt;
    private ILogger? _logger;

    public object? Init(string parameters, ILogger logger)
    {
        var kv = IODeviceParametersParser.ParseParameters(parameters);
        _address = IODeviceParametersParser.ParseUShort(kv, "address") ?? 
                   throw new IODeviceException("timer: missing or wrong address parameter");
        if (!kv.TryGetValue("bits", out var bits) ||
            !int.TryParse(bits, out _maxValue))
            throw new IODeviceException("timer: missing or wrong bits parameter");
        if (!kv.TryGetValue("interrupt", out var interrupt) ||
            !uint.TryParse(interrupt, out _interrupt) || _interrupt == 0)
            throw new IODeviceException("timer: missing or wrong interrupt parameter");
        _maxValue = (1<<_maxValue) - 1;
        _logger = logger;
        _counter = 0;
        return null;
    }

    public void IoRead(IoEvent ev)
    {
        if (ev.Address == _address)
            _logger?.Error("Timer io read");
    }

    public void IoWrite(IoEvent ev)
    {
        if (ev.Address == _address && (ev.Data & 1) != 0)
            ev.InterruptClearMask = ~_interrupt;
    }

    public uint TicksUpdate(int cpuSpeed, int ticks, bool wfi, uint interruptAck, out uint interruptClearMask)
    {
        interruptClearMask = 0;
        if (_counter == _maxValue)
        {
            _counter = 0;
            return _interrupt;
        }
        _counter++;
        return 0;
    }
}