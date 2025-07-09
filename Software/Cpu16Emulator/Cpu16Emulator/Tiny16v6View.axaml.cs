using Avalonia.Controls;
using Cpu16EmulatorCpus;

namespace Cpu16Emulator;

public partial class Tiny16v6View : UserControl, ICpuView
{
    internal class Register(Tiny16v6 cpu, byte index)
    {
        public override string ToString()
        {
            return index.ToString("00") + " " + cpu.Registers[index].ToString("X4");
        }
    }

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

        for (var row = 0; row < 2; row++)
        {
            for (var col = 0; col < 16; col++)
            {
                var l = new Label
                {
                    [Grid.RowProperty] = row,
                    [Grid.ColumnProperty] = col,
                    Content = GetRegistersContent(row, col)
                };
                GRegisters.Children.Add(l);
            }
        }
    }

    private static string GetRegistersContent(int row, int col) => row == 0 ? col.ToString() : "0000";
    
    private void Update(bool markChangesAsBold)
    {
        if (_cpu == null)
            return;
        LbPc.Content = _cpu.Pc.ToString("X4");
        CPU16View.UpdateContent(LbSp, _cpu.Sp, markChangesAsBold, "X4");
        CPU16View.UpdateContent(LbHlt, _cpu.Hlt, markChangesAsBold);
        CPU16View.UpdateContent(LbError, _cpu.Error, markChangesAsBold);
        CPU16View.UpdateContent(LbC, _cpu.C, markChangesAsBold);
        CPU16View.UpdateContent(LbZ, _cpu.Z, markChangesAsBold);
        CPU16View.UpdateContent(LbN, _cpu.N, markChangesAsBold);
        CPU16View.UpdateContent(LbInterrupt, _cpu.Interrupt, markChangesAsBold, "0");
        LbTicks.Content = _cpu.Ticks.ToString();
        var idx = 0;
        for (var col = 0; col < 16; col++)
            CPU16View.UpdateContent((Label)GRegisters.Children[16 + col], _cpu.Registers[idx++], markChangesAsBold, "X4");
    }

    public void Update() => Update(true);
}