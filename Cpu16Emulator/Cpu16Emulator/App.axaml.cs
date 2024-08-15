using System;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text.Json;
using Avalonia;
using Avalonia.Controls.ApplicationLifetimes;
using Avalonia.Markup.Xaml;
using Cpu16EmulatorCommon;

namespace Cpu16Emulator;

public partial class App : Application
{
    public override void Initialize()
    {
        AvaloniaXamlLoader.Load(this);
    }

    public override void OnFrameworkInitializationCompleted()
    {
        if (ApplicationLifetime is IClassicDesktopStyleApplicationLifetime desktop)
        {
            if (desktop.Args?.Length != 1)
            {
                desktop.MainWindow = new MessageBoxWindow("Error", "Invalid number of arguments");
            }
            else
            {
                try
                {
                    var config = JsonSerializer.Deserialize<Configuration>(desktop.Args[0]);
                    if (config == null || config.CpuSpeed == 0)
                        throw new Exception("incorrect configuration file");
                    var ioDevices = LoadIODevices(config.IODevices);
                    var code = File.ReadAllLines(desktop.Args[1]);
                    var cpu = new Cpu16(code, 16, config.CpuSpeed * 1000);
                    desktop.MainWindow = new MainWindow(cpu, ioDevices);
                }
                catch (Exception e)
                {
                    desktop.MainWindow = new MessageBoxWindow("Error", e.Message);
                }
            }
        }

        base.OnFrameworkInitializationCompleted();
    }

    private static IODevice[] LoadIODevices(IODeviceFile[] deviceFiles)
    {
        return deviceFiles.SelectMany(LoadIODevices).ToArray();
    }
    
    private static IODevice[] LoadIODevices(IODeviceFile deviceFile)
    {
        var assembly = Assembly.LoadFile(deviceFile.FileName);
        return assembly.GetExportedTypes()
            .Where(t => typeof(IIODevice).IsAssignableFrom(t))
            .Select(t => new IODevice {
                Device = (IIODevice)(Activator.CreateInstance(t) ?? throw new IODeviceException($"cannot create instance for type {t.Name}")),
                Parameters = deviceFile.Parameters
            })
            .ToArray();
    }
}

public class Configuration
{
    public int CpuSpeed { get; set; }
    public IODeviceFile[] IODevices { get; set; }
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
