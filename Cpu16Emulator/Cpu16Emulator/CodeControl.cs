using System.Collections.Generic;
using System.Globalization;
using Avalonia;
using Avalonia.Controls;
using Avalonia.Media;

namespace Cpu16Emulator;

public class CodeControl: Control
{
    public CodeLine[]? Lines { get; set; }
    private int _topLine;
    private Typeface _font;
    private double _fontHeight;
    private double _rowHeight;

    public CodeControl()
    {
        _topLine = 0;
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
        for (var i = _topLine; i < Lines.Length; i++)
        {
            var point = new Point(0, y);
            var formattedText = new FormattedText(Lines[i].ToString(), CultureInfo.InvariantCulture,
                FlowDirection.LeftToRight, _font, _fontHeight, Brushes.Black);
            context.DrawText(formattedText, point);
            y += _rowHeight;
        }
    }

    protected override Size MeasureOverride(Size availableSize)
    {
        var h = Lines?.Length * _rowHeight ?? 0;
        return new Size(Width, h);
    }
}