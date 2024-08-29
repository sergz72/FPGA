using Avalonia.Controls;
using Cpu16EmulatorCommon;

namespace IODeviceLCD1;

public class IODeviceLCD1: IIODevice
{
    private ushort _startAddress, _endAddress;
    private ILogger? _logger;
    private ILcdDriver? _lcdDriver;

    public Control? Init(string parameters, ILogger logger)
    {
        var kv = IODeviceParametersParser.ParseParameters(parameters);

        if (!kv.TryGetValue("addressRange", out var addressRange))
            throw new IODeviceException("IODeviceLCD1: missing addressRange parameter");
        var parts = addressRange.Split('-');
        if (parts.Length != 2)
            throw new IODeviceException("IODeviceLCD1: wrong addressRange parameter");
        
        _startAddress = IODeviceParametersParser.ParseUShort(parts[0]) ?? 
                        throw new IODeviceException("IODeviceLCD1: wrong start address parameter");
        _endAddress = IODeviceParametersParser.ParseUShort(parts[1]) ?? 
                        throw new IODeviceException("IODeviceLCD1: wrong end address parameter");

        var width = IODeviceParametersParser.ParseUShort(kv, "width"); 
        var height = IODeviceParametersParser.ParseUShort(kv, "height"); 

        if (!kv.TryGetValue("driver", out var driverName))
            throw new IODeviceException("IODeviceLCD1: missing driver parameter");

        var driverParameters = kv.GetValueOrDefault("driverParameters", "");
        
        _logger = logger;
        
        _lcdDriver = BuildLcdDriver(driverName, driverParameters, width, height, logger);
        
        return _lcdDriver.CreateControl();
    }

    private ILcdDriver BuildLcdDriver(string driverName, string driverParameters, ushort? width, ushort? height,
                                        ILogger logger)
    {
        if (driverName == "ks0108")
            return new KS0108(driverParameters, logger);
        throw new IODeviceException("IODeviceLCD1: wrong driver name");
    }

    public void IoRead(IoEvent ev)
    {
        if (ev.Address >= _startAddress && ev.Address <= _endAddress)
            _logger?.Error("IODeviceLCD1 io read");
    }

    public void IoWrite(IoEvent ev)
    {
        if (ev.Address >= _startAddress && ev.Address <= _endAddress)
            _lcdDriver?.Write(ev.Address, (byte)ev.Data);
    }

    public bool? TicksUpdate(int cpuSped, int ticks)
    {
        return null;
    }
}

internal interface ILcdDriver
{
    void Write(ushort address, byte data);
    Control CreateControl();
}
