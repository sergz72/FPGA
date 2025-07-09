using Avalonia.Controls;
using Cpu16EmulatorCpus;

namespace Cpu16Emulator;

public partial class Tiny16v6View : UserControl, ICpuView
{
    private Tiny16v6? _cpu;
    public Tiny16v6? Cpu
    {
        get => _cpu;
        set
        {
            _cpu = value;
            Update(false);
        }
    }

    public Tiny16v6View()
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