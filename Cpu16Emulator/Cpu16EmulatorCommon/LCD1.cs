using Avalonia;
using Avalonia.Controls;
using Avalonia.Media;

namespace Cpu16EmulatorCommon;

public class LCD1: Control
{
    private readonly int _scaledWidth;
    private readonly int _scaledHeight;
    private readonly int _scale;
    protected readonly ushort[] _ram;
    
    public bool On { get; set; }

    public LCD1(ushort[] ram, int width, int scale)
    {
        _ram = ram;
        var height = (ram.Length << 4) / width;
        _scale = scale;
        _scaledHeight = height * scale;
        _scaledWidth = width * scale;
        var r = new Random();
        for (var i = 0; i < ram.Length; i++)
            ram[i] = (ushort)r.Next(ushort.MaxValue);
        On = false;
    }
    
    public override void Render(DrawingContext context)
    {
        context.FillRectangle(Brushes.White, new Rect(0, 0, Width, Height));
        if (!On) return;
        
        var idx = 0;
        var bit = 1;
        for (var y = 0; y < _scaledHeight; y += _scale)
        {
            for (var x = 0; x < _scaledWidth; x += _scale)
            {
                if ((_ram[idx] & bit) != 0)
                    context.FillRectangle(Brushes.Black, new Rect(x, y, _scale, _scale));
                if (bit == 0x8000)
                {
                    bit = 1;
                    idx++;
                }
                else
                    bit <<= 1;
            }
        }
    }

    public static LCD1 Create(ushort[] ram, string parameters)
    {
        var parts = parameters.Split(',');
        if (parts.Length != 2)
            throw new IODeviceException("LCD1: invalid parameters specified");
        if (!int.TryParse(parts[0], out var width))
            throw new IODeviceException("LCD1: invalid width parameter");
        if (!int.TryParse(parts[1], out var scale))
            throw new IODeviceException("LCD1: invalid scale parameter");
        return new LCD1(ram, width, scale);
    }

    protected override Size MeasureOverride(Size availableSize)
    {
        return new Size(_scaledWidth, _scaledHeight);
    }
}