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

    private bool _on;

    public bool On
    {
        get => _on;
        set
        {
            if (value == _on) return;
            _on = value;
            if (value)
                InvalidateVisual();
        }
    }

    public LCD1(ushort[] ram, int width, int scale, bool on = false)
    {
        _ram = ram;
        var height = (ram.Length << 4) / width;
        _scale = scale;
        _scaledHeight = height * scale;
        _scaledWidth = width * scale;
        On = on;
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
        if (parts.Length != 3)
            throw new IODeviceException("LCD1: invalid parameters specified");
        if (!int.TryParse(parts[0], out var width))
            throw new IODeviceException("LCD1: invalid width parameter");
        if (!int.TryParse(parts[1], out var scale))
            throw new IODeviceException("LCD1: invalid scale parameter");
        if (!bool.TryParse(parts[2], out var on))
            throw new IODeviceException("LCD1: invalid scale parameter");
        return new LCD1(ram, width, scale, on);
    }

    protected override Size MeasureOverride(Size availableSize)
    {
        return new Size(_scaledWidth, _scaledHeight);
    }
}