using Cpu16EmulatorCommon;

namespace Cpu16EmulatorCpus;

public class IODevices(Cpu cpu, IODevice[] devices, ILogger logger)
{
    public void IoRead(object? sender, IoEvent e)
    {
        foreach (var d in devices)
            d.Device.IoRead(e);
        logger.Info($"IO read, address = {e.Address:X4}, data = {e.Data:X4}");
        if (e.InterruptClearMask != null)
            cpu.Interrupt &= (uint)e.InterruptClearMask;
    }

    public void IoWrite(object? sender, IoEvent e)
    {
        logger.Info($"IO write, address = {e.Address:X4}, data = {e.Data:X4}");
        foreach (var d in devices)
            d.Device.IoWrite(e);
        if (e.InterruptClearMask != null)
            cpu.Interrupt &= (uint)e.InterruptClearMask;
    }

    public void TicksUpdate(object? sender, int ticks)
    {
        foreach (var d in devices)
        {
            uint interruptAck = 0;
            if (cpu is ForthCPU fcpu)
                interruptAck = fcpu.InterruptAck;
            var setMask = d.Device.TicksUpdate(cpu.Speed, ticks, cpu.Wfi, interruptAck, out var clearMask);
            cpu.Interrupt |= setMask;
            cpu.Interrupt &= ~clearMask;
        }
    }
}
