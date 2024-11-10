using Cpu16EmulatorCommon;

namespace IODeviceI2CSlave;

public class MCP3426: IODeviceI2CSlave.I2CDevice
{
    private readonly byte[][] _values;
    private int _channel;
    
    internal MCP3426(string parameters)
    {
        var kv = IODeviceParametersParser.ParseParameters(parameters);
        _values = new byte[2][];
        _values[0] = new byte[2];
        _values[1] = new byte[2];
        var value = IODeviceParametersParser.ParseUShort(kv, "value1") ??
                    throw new IODeviceException("MCP3426: missing or wrong value1 parameter");
        _values[0][0] = (byte)(value >> 8);
        _values[0][1] = (byte)(value & 0xFF);
        value = IODeviceParametersParser.ParseUShort(kv, "value2") ??
                    throw new IODeviceException("MCP3426: missing or wrong value2 parameter");
        _values[1][0] = (byte)(value >> 8);
        _values[1][1] = (byte)(value & 0xFF);
    }
    
    public byte Read(ILogger logger, string name, int byteNo)
    {
        logger.Info($"{name} read {byteNo}");
        return byteNo < 2 ? _values[_channel][byteNo] : (byte)0;
    }

    public void Write(ILogger logger, string name, int byteNo, byte value)
    {
        if (byteNo == 0)
            _channel = (value >> 5) & 3;
        logger.Info($"{name} write {byteNo} {value}, selected channel = {_channel}");
    }
}
