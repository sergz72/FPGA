namespace Cpu16EmulatorCommon;

public class Configuration
{
    public string Cpu { get; set; }
    public int CpuSpeed { get; set; }
    public string LogFile { get; set; }
    public IODeviceFile[] IODevices { get; set; }
    public string[]? CpuOptions { get; set; }
}

public class IODeviceFile
{
    public string FileName { get; set; }
    public string Parameters { get; set; }
}

public class IODevice
{
    public IIODevice Device;
    public string Parameters { get; set; }
}
