using System;
using Avalonia.Controls;
using Avalonia.Input;
using Avalonia.Interactivity;
using Avalonia.Media;
using Cpu16EmulatorCommon;

namespace Cpu16Emulator;

public partial class MainWindow : Window, ILogger
{
    private readonly Cpu16 _cpu;
    private readonly IODevice[] _devices;
    
    public MainWindow(Cpu16 cpu, IODevice[] devices)
    {
        InitializeComponent();

        _cpu = cpu;
        _devices = devices;

        LbCode.Lines = _cpu.Code;

        CpuView.Cpu = cpu;
        cpu.IoReadEventHandler = IoRead;
        cpu.IoWriteEventHandler = IoWrite;
        cpu.TicksEventHandler = TicksUpdate;

        foreach (var d in devices)
        {
            var c = d.Device.Init(d.Parameters, this);
            if (c != null)
                SpIODevices.Children.Add(c);
        }
    }

    private void IoRead(object? sender, IoEvent e)
    {
        foreach (var d in _devices)
            d.Device.IoRead(e);
        Info($"IO read, address = {e.Address:X4}");
        if (e.Interrupt != null)
            _cpu.Interrupt = (bool)e.Interrupt;
    }

    private void IoWrite(object? sender, IoEvent e)
    {
        foreach (var d in _devices)
            d.Device.IoWrite(e);
        Info($"IO write, address = {e.Address:X4}, data = {e.Data:X4}");
        if (e.Interrupt != null)
            _cpu.Interrupt = (bool)e.Interrupt;
    }

    private void TicksUpdate(object? sender, int ticks)
    {
        foreach (var d in _devices)
        {
            var i = d.Device.TicksUpdate(_cpu.Speed, ticks);
            if (i != null)
                _cpu.Interrupt = (bool)i;
        }
    }

    private void InputElement_OnKeyDown(object? sender, KeyEventArgs e)
    {
        switch (e.Key)
        {
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
        CpuView.Update();
        LbCode.InvalidateVisual();
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
        ViewsUpdate();
    }

    private void Stop_OnClick(object? sender, RoutedEventArgs e)
    {
    }

    private void Log(string level, string message)
    {
        LbLog.Items.Add($"{_cpu.Ticks:d10} {level} {message}");
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
    }
}