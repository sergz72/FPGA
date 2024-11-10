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
using Cpu16EmulatorCpus;

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
                    var (cpu, ioDevices, logFile, _) =
                        Cpu.Load(desktop.Args[0], desktop.Args[1]);
                    if (logFile == null)
                        throw new Exception("null logFile");
                    ICpuView cpuView = cpu switch
                    {
                        Cpu16Lite cpu16 => new CPU16View { Cpu = cpu16 },
                        Tiny16v4 t16v4 => new Tiny16v4View { Cpu = t16v4 },
                        ForthCPU fcpu => new ForthCPUView { Cpu = fcpu },
                        _ => throw new Exception("unknown cpu")
                    };
                    desktop.MainWindow = new MainWindow(cpu, ioDevices, logFile, cpuView);
                }
                catch (Exception e)
                {
                    desktop.MainWindow = new MessageBoxWindow("Error", e.Message);
                }
            }
        }

        base.OnFrameworkInitializationCompleted();
    }
}
