using Cpu16EmulatorCommon;

namespace IODeviceI2CSlave;

public class MCP3425: IODeviceI2CSlave.I2CDevice
{
    private readonly ushort _value;
    internal MCP3425(string parameters)
    {
        var kv = IODeviceParametersParser.ParseParameters(parameters);
        _value = IODeviceParametersParser.ParseUShort(kv, "value") ??
                 throw new IODeviceException("MCP3425: missing or wrong value parameter");
    }
    
    public byte Read(ILogger logger, string name, int byteNo)
    {
        logger.Info($"{name} read {byteNo}");
        return (byte)(byteNo + 50);
    }

    public void Write(ILogger logger, string name, int byteNo, byte value)
    {
        logger.Info($"{name} write {byteNo} {value}");
    }
}