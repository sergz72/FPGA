using Avalonia;
using Avalonia.Controls;
using Avalonia.Markup.Xaml;

namespace Cpu16Emulator;

public partial class Tiny16v4View : UserControl, ICpuView
{
    private Tiny16v4? _cpu;
    public Tiny16v4? Cpu
    {
        get => _cpu;
        set
        {
            _cpu = value;
            Update(false);
        }
    }

    public Tiny16v4View()
    {
        InitializeComponent();
    }

    private void Update(bool markChangesAsBold)
    {
        if (_cpu == null)
            return;
    }

    public void Update() => Update(true);
}