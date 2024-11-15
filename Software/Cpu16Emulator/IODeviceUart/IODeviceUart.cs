using Cpu16EmulatorCommon;

namespace IODeviceUart;

public class IODeviceUart: IIODevice
{
    private ILogger? _logger;
    private uint _address;
    private uint _data;
    private uint _interrupt;
    
    public object? Init(string parameters, ILogger logger)
    {
        var kv = IODeviceParametersParser.ParseParameters(parameters);
        _address = IODeviceParametersParser.ParseUInt(kv, "address") ?? 
                        throw new IODeviceException("uart: missing or wrong address parameter");
        _interrupt = IODeviceParametersParser.ParseUInt(kv, "interrupt") ?? 
                   throw new IODeviceException("uart: missing or wrong address parameter");
        _logger = logger;
        return null;
    }

    public void IoRead(IoEvent ev)
    {
        if (ev.Address == _address)
            ev.Data = _data;
    }

    public void IoWrite(IoEvent ev)
    {
        if (ev.Address == _address)
            Console.Write((char)ev.Data);
    }

    public uint TicksUpdate(int cpuSped, int ticks, bool wfi, uint interruptAck, out uint interruptClearMask)
    {
        if (wfi)
        {
            if (Console.KeyAvailable)
            {
                _data = (uint)(Console.ReadKey(true).KeyChar & 0x7F);
                interruptClearMask = 0;
                return _interrupt;
            }
            Thread.Sleep(100);
        }
        interruptClearMask = interruptAck & _interrupt;
        return 0;
    }
}