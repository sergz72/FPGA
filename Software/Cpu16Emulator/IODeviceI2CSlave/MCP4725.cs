using Cpu16EmulatorCommon;

namespace IODeviceI2CSlave;

public class MCP4725: IODeviceI2CSlave.I2CDevice
{
    internal MCP4725(string parameters)
    {
        
    }
    
    public byte Read(ILogger logger, string name, int byteNo)
    {
        logger.Error($"{name} read called");
        return 0;
    }

    public void Write(ILogger logger, string name, int byteNo, byte value)
    {
        logger.Info($"{name} write {byteNo} {value}");
    }
}