using System;
using Avalonia.Controls;
using Avalonia.Input;
using Avalonia.Interactivity;
using Cpu16EmulatorCommon;

namespace Cpu16Emulator;

public partial class MainWindow : Window
{
    private readonly Cpu16 _cpu;
    private readonly IODevice[] _devices;
    
    public MainWindow(Cpu16 cpu, IODevice[] devices)
    {
        InitializeComponent();

        _cpu = cpu;
        _devices = devices;

        foreach (var line in cpu.Code)
            LbCode.Items.Add(line);

        CpuView.Cpu = cpu;
        cpu.IoReadEventHandler = IoRead;
        cpu.IoWriteEventHandler = IoWrite;
        cpu.TicksEventHandler = TicksUpdate;

        foreach (var d in devices)
        {
            var c = d.Device.Init(d.Parameters);
            if (c != null)
                SpIODevices.Children.Add(c);
        }
    }

    private void IoRead(object? sender, IoEvent e)
    {
        foreach (var d in _devices)
            d.Device.IoRead(e);
        LStatus.Content = $"IO read, address = {e.Address:X4}";
    }

    private void IoWrite(object? sender, IoEvent e)
    {
        foreach (var d in _devices)
            d.Device.IoWrite(e);
        LStatus.Content = $"IO write, address = {e.Address:X4}, data = {e.Data:X4}";
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
        LbCode.SelectedIndex = _cpu.Pc;
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
        LStatus.Content = "";
        _cpu.Step();
        ViewsUpdate();
    }

    private void StepOver_OnClick(object? sender, RoutedEventArgs e)
    {
        LStatus.Content = "";
        _cpu.StepOver();
        ViewsUpdate();
    }

    private void Reset_OnClick(object? sender, RoutedEventArgs e)
    {
        LStatus.Content = "";
        _cpu.Reset();
        ViewsUpdate();
    }

    private void Stop_OnClick(object? sender, RoutedEventArgs e)
    {
        LStatus.Content = "";
    }
}