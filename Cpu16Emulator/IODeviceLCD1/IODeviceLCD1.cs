using Avalonia.Controls;
using Cpu16EmulatorCommon;

namespace IODeviceLCD1;

public class IODeviceLCD1: IIODevice
{
    public Control? Init(string parameters, ILogger logger)
    {
        return null;
    }

    public void IoRead(IoEvent ev)
    {
    }

    public void IoWrite(IoEvent ev)
    {
    }

    public bool? TicksUpdate(int cpuSped, int ticks)
    {
        return null;
    }
}