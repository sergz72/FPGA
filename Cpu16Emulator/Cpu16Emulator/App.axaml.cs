using System;
using System.IO;
using Avalonia;
using Avalonia.Controls.ApplicationLifetimes;
using Avalonia.Markup.Xaml;

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
                    var code = File.ReadAllLines(desktop.Args[0]);
                    var cpu = new Cpu16(code, 16);
                    desktop.MainWindow = new MainWindow(cpu);
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