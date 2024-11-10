using Avalonia.Controls;
using Avalonia.Media;
using Cpu16EmulatorCpus;

namespace Cpu16Emulator;

public partial class CPU16View : UserControl, ICpuView
{
    internal class Register(Cpu16Lite cpu, byte index)
    {
        private readonly byte _index = index;
        private readonly Cpu16Lite _cpu = cpu;

        public override string ToString()
        {
            return _index.ToString("000") + " " + _cpu.Registers[_index].ToString("X4");
        }
    }

    private Cpu16Lite? _cpu;
    public Cpu16Lite? Cpu
    {
        get => _cpu;
        set
        {
            _cpu = value;
            Update(false);
        }
    }

    public CPU16View()
    {
        InitializeComponent();

        for (var i = 0; i < 17 * 17; i++)
        {
            var col = i % 17;
            var row = i / 17;
            var l = new Label
            {
                [Grid.RowProperty] = row,
                [Grid.ColumnProperty] = col,
                Content = GetRegistersContent(row, col)
            };
            GRegisters.Children.Add(l);
        }
    }

    private string GetRegistersContent(int row, int col)
    {
        if (row == 0)
            return col == 0 ? "" : (col - 1).ToString();
        if (col == 0)
            return (row - 1).ToString();
        return "0000";
    }

    private void Update(bool markChangesAsBold)
    {
        if (_cpu == null)
            return;
        LbPc.Content = _cpu.Pc.ToString("X4");
        UpdateContent(LbSp, _cpu.Sp, markChangesAsBold, "X2");
        UpdateContent(LbRp, _cpu.Rp, markChangesAsBold, "X2");
        UpdateContent(LbHlt, _cpu.Hlt, markChangesAsBold);
        UpdateContent(LbError, _cpu.Error, markChangesAsBold);
        UpdateContent(LbC, _cpu.C, markChangesAsBold);
        UpdateContent(LbZ, _cpu.Z, markChangesAsBold);
        UpdateContent(LbN, _cpu.N, markChangesAsBold);
        UpdateContent(LbInterrupt, _cpu.Interrupt, markChangesAsBold, "X8");
        LbTicks.Content = _cpu.Ticks.ToString();
        var idx = 0;
        for (var row = 1; row < 17; row++)
        {
            for (var col = 1; col < 17; col++)
                UpdateContent((Label)GRegisters.Children[row * 17 + col], _cpu.Registers[idx++], markChangesAsBold, "X4");
        }
    }

    private static void UpdateContent(Label l, uint v, bool markChangesAsBold, string format)
    {
        var text = v.ToString(format);
        if (text != l.Content?.ToString())
        {
            l.Content = text;
            if (markChangesAsBold)
                l.FontWeight = FontWeight.Bold;
        }
        else
            l.FontWeight = FontWeight.Normal;
    }
    
    private static void UpdateContent(Label l, ushort v, bool markChangesAsBold, string format)
    {
        var text = v.ToString(format);
        if (text != l.Content?.ToString())
        {
            l.Content = text;
            if (markChangesAsBold)
                l.FontWeight = FontWeight.Bold;
        }
        else
            l.FontWeight = FontWeight.Normal;
    }

    private static void UpdateContent(Label l, bool v, bool markChangesAsBold)
    {
        var text = v ? "1" : "0";
        if (text != l.Content?.ToString())
        {
            l.Content = text;
            if (markChangesAsBold)
                l.FontWeight = FontWeight.Bold;
        }
        else
            l.FontWeight = FontWeight.Normal;
    }
    
    public void Update() => Update(true);
}