using System.IO;
using Avalonia;
using Avalonia.Controls;
using Avalonia.Input;
using Avalonia.Interactivity;
using Cpu16EmulatorCommon;
using Cpu16EmulatorCpus;

namespace Cpu16Emulator;

public partial class MainWindow : Window, ILogger
{
    private readonly Cpu _cpu;
    private readonly StreamWriter? _logFile;
    private readonly ICpuView _cpuView;
    private readonly IODevices _ioDevices;

    private Point _mousePosition;
    
    public MainWindow(Cpu cpu, IODevice[] devices, string logFile, ICpuView cpuView)
    {
        InitializeComponent();

        _logFile = logFile != "" ? new StreamWriter(logFile) : null;
            
        _cpu = cpu;
        _cpuView = cpuView;

        _ioDevices = new IODevices(cpu, devices, this);
        
        LbCode.Lines = _cpu.Code;
        LbCode.Breakpoints = _cpu.Breakpoints;

        CpuView.Children.Add((Control)cpuView);
        
        cpu.IoReadEventHandler = _ioDevices.IoRead;
        cpu.IoWriteEventHandler = _ioDevices.IoWrite;
        cpu.TicksEventHandler = _ioDevices.TicksUpdate;

        foreach (var d in devices)
        {
            var c = d.Device.Init(d.Parameters, this);
            if (c != null)
                SpIODevices.Children.Add((Control)c);
        }
    }
    
    private void InputElement_OnKeyDown(object? sender, KeyEventArgs e)
    {
        switch (e.Key)
        {
            case Key.F5:
                Run_OnClick(null, new RoutedEventArgs());
                break;
            case Key.F10:
                StepOver_OnClick(null, new RoutedEventArgs());
                break;
            case Key.F11:
                Step_OnClick(null, new RoutedEventArgs());
                break;
        }
        e.Handled = true;
    }

    private void ViewsUpdate()
    {
        _cpuView.Update();
        LbCode.Update(_cpu.Pc);
    }

    private void Exit_OnClick(object? sender, RoutedEventArgs e)
    {
        Close();
    }

    private void FileOpen_OnClick(object? sender, RoutedEventArgs e)
    {
    }

    private void Step_OnClick(object? sender, RoutedEventArgs e)
    {
        _cpu.Step();
        ViewsUpdate();
    }

    private void StepOver_OnClick(object? sender, RoutedEventArgs e)
    {
        _cpu.StepOver();
        ViewsUpdate();
    }

    private void Reset_OnClick(object? sender, RoutedEventArgs e)
    {
        _cpu.Reset();
        LbLog.Items.Clear();
        ViewsUpdate();
    }

    private void Run_OnClick(object? sender, RoutedEventArgs e)
    {
        _cpu.Run();
        ViewsUpdate();
    }

    private void ClearLog_OnClick(object? sender, RoutedEventArgs e)
    {
        LbLog.Items.Clear();
    }
    
    private void Stop_OnClick(object? sender, RoutedEventArgs e)
    {
    }

    private void Log(string level, string message)
    {
        var formatted = $"{_cpu.Ticks:d10} {level} {message}";
        _logFile?.WriteLine(formatted);
        _logFile?.Flush();
        LbLog.Items.Add(formatted);
    }
    
    public void SetLevel(LogLevel level)
    {
    }

    public void Debug(string message)
    {
        Log("DEBUG", message);
    }

    public void Info(string message)
    {
        Log("INFO", message);
    }

    public void Warning(string message)
    {
        Log("WARN", message);
    }

    public void Error(string message)
    {
        Log("ERROR", message);
    }

    private void AddBreakpoint_OnClick(object? sender, RoutedEventArgs e)
    {
        var pc = LbCode.GetPc(_mousePosition);
        if (pc != null)
        {
            _cpu.Breakpoints.Add((ushort)pc);
            LbCode.Update(_cpu.Pc);
        }
    }

    private void LbCode_OnContextRequested(object? sender, ContextRequestedEventArgs e)
    {
        e.TryGetPosition(LbCode, out _mousePosition);
    }

    private void DeleteBreakpoint_OnClick(object? sender, RoutedEventArgs e)
    {
        var pc = LbCode.GetPc(_mousePosition);
        if (pc != null && _cpu.Breakpoints.Contains((ushort)pc))
        {
            _cpu.Breakpoints.Remove((ushort)pc);
            LbCode.Update(_cpu.Pc);
        }
    }
}