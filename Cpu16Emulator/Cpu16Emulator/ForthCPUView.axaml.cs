using Avalonia.Controls;
using Cpu16EmulatorCpus;

namespace Cpu16Emulator;

public partial class ForthCPUView : UserControl, ICpuView
{
    private ForthCPU? _cpu;
    public ForthCPU? Cpu
    {
        get => _cpu;
        set
        {
            _cpu = value;
            Update(false);
        }
    }

    public ForthCPUView()
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