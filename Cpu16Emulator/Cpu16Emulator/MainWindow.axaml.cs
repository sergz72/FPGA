using Avalonia.Controls;
using Avalonia.Input;
using Avalonia.Interactivity;

namespace Cpu16Emulator;

public partial class MainWindow : Window
{
    private readonly Cpu16 _cpu;
    public MainWindow(Cpu16 cpu)
    {
        InitializeComponent();

        _cpu = cpu;

        foreach (var line in cpu.Code)
            LbCode.Items.Add(line);

        CpuView.Cpu = cpu;
    }

    private void InputElement_OnKeyDown(object? sender, KeyEventArgs e)
    {
        switch (e.Key)
        {
            case Key.F10:
                _cpu.StepOver();
                ViewsUpdate();
                break;
            case Key.F11:
                _cpu.Step();
                ViewsUpdate();
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
}