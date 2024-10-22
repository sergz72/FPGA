using System;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text.Json;
using Avalonia;
using Avalonia.Controls;
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
            if (desktop.Args?.Length != 2)
            {
                desktop.MainWindow = new MessageBoxWindow("Error", "Invalid number of arguments");
            }
            else
            {
                try
                {
                    var stream = File.OpenRead(desktop.Args[0]);
                    var config = JsonSerializer.Deserialize<Configuration>(stream);
                    if (config == null || config.CpuSpeed == 0 || config.Cpu == "")
                        throw new Exception("incorrect configuration file");
                    var code = File.ReadAllLines(desktop.Args[1]);
                    Cpu cpu;
                    ICpuView cpuView;
                    switch (config.Cpu)
                    {
                        case "Cpu16Lite":
                            cpu = new Cpu16Lite(code, config.CpuSpeed * 1000);
                            cpuView = new CPU16View
                            {
                                Cpu = (Cpu16Lite)cpu
                            };
                            break;
                        case "Tiny16v4":
                            cpu = new Tiny16v4(code, config.CpuSpeed * 1000);
                            cpuView = new Tiny16v4View
                            {
                                Cpu = (Tiny16v4)cpu
                            };
                            break;
                        default:
                            throw new Exception("invalid cpu");
                    }
                    var ioDevices = LoadIODevices(config.IODevices);
                    cpu.Reset();
                    desktop.MainWindow = new MainWindow(cpu, ioDevices, config.LogFile, cpuView);
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
        var assembly = Assembly.LoadFile(Path.GetFullPath(deviceFile.FileName));
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
    public string Cpu { get; set; }
    public int CpuSpeed { get; set; }
    public string LogFile { get; set; }
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
