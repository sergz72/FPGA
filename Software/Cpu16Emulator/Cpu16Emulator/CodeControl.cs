using System.Collections.Generic;
using System.Globalization;
using Avalonia;
using Avalonia.Controls;
using Avalonia.Media;
using Cpu16EmulatorCpus;

namespace Cpu16Emulator;

public sealed class CodeControl: Control
{
    public CodeLine[]? Lines { get; set; }
    public HashSet<uint>? Breakpoints { get; set; }
    
    private Typeface _font;
    private double _fontHeight;
    private double _rowHeight;
    private uint _pc;

    public CodeControl()
    {
        _font = Typeface.Default;
        _fontHeight = 16;
        var formattedText = new FormattedText("Test", CultureInfo.InvariantCulture,
            FlowDirection.LeftToRight, _font, _fontHeight, Brushes.Black);
        _rowHeight = formattedText.Height;
    }
    
    public override void Render(DrawingContext context)
    {
        if (Lines == null)
            return;
        double y = 0;
        foreach (var l in Lines)
        {
            var point = new Point(0, y);
            var r = new Rect(point, new Size(Width, _rowHeight));
            context.FillRectangle(GetFillBrush(l), r);
            var formattedText = new FormattedText(l.ToString(), CultureInfo.InvariantCulture,
                FlowDirection.LeftToRight, _font, _fontHeight, Brushes.Black);
            context.DrawText(formattedText, point);
            y += _rowHeight;
        }
    }

    private IBrush GetFillBrush(CodeLine l)
    {
        return _pc == l.Pc ? Brushes.LightBlue :
            (Breakpoints?.Contains((ushort)l.Pc) ?? false) ? Brushes.Red : Brushes.White;
    }

    protected override Size MeasureOverride(Size availableSize)
    {
        var h = Lines?.Length * _rowHeight ?? 0;
        return new Size(Width, h);
    }

    internal void Update(uint pc)
    {
        _pc = pc;
        if (Parent is ScrollViewer sv)
        {
            var y = pc * _rowHeight;
            var offset = sv.Offset.Y;
            var h = sv.Viewport.Height;
            if (y < offset || y > offset + h)
                sv.Offset = new Point(0, y);
        }
        InvalidateVisual();
    }

    public int? GetPc(Point mousePosition)
    {
        var pc = (int)(mousePosition.Y / _rowHeight);
        if (pc < 0 || pc >= (Lines?.Length ?? 0))
            return null;
        return pc;
    }
}