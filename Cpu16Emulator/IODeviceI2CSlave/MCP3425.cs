using Cpu16EmulatorCommon;

namespace IODeviceI2CSlave;

public class MCP3425: IODeviceI2CSlave.I2CDevice
{
    private readonly byte[] _value;
    internal MCP3425(string parameters)
    {
        var kv = IODeviceParametersParser.ParseParameters(parameters);
        _value = new byte[2];
        var value = IODeviceParametersParser.ParseUShort(kv, "value") ??
                 throw new IODeviceException("MCP3425: missing or wrong value parameter");
        _value[0] = (byte)(value >> 8);
        _value[1] = (byte)(value & 0xFF);
    }
    
    public byte Read(ILogger logger, string name, int byteNo)
    {
        logger.Info($"{name} read {byteNo}");
        return byteNo < 2 ? _value[byteNo] : (byte)0;
    }

    public void Write(ILogger logger, string name, int byteNo, byte value)
    {
        logger.Info($"{name} write {byteNo} {value}");
    }
}