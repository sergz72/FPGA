using System;
using System.IO;
using System.Linq;
using Avalonia;
using Avalonia.Controls;
using Avalonia.Media;

namespace LcdTest;

public sealed class TwoColorLcd: Control
{
    private int _width, _height, _scale, _wordWidth;
    private ushort[] _displayRam = [];
    private ushort[] _fontRam = [];
    private ushort _charCount, _fontWidth, _fontHeight;
    
    public void Init(int width, int height, int scale, string fontFileName)
    {
        _width = width;
        _height = height;
        _scale = scale;
        _wordWidth = width >> 4;
        _displayRam = new ushort[_wordWidth * height];
        var r = new Random();
        for (var i = 0; i < _displayRam.Length; i++)
            _displayRam[i] = (ushort)r.Next(ushort.MaxValue);
        LoadFontFile(fontFileName);
    }

    private void LoadFontFile(string fontFileName)
    {
        var lines = File.ReadAllLines(fontFileName);
        _fontRam = lines.Select(ushort.Parse).ToArray();
        _fontWidth = _fontRam[0];
        _fontHeight = _fontRam[1];
        _charCount = _fontRam[2];
    }

    public void Clear()
    {
        for (var i = 0; i < _displayRam.Length; i++)
            _displayRam[i] = 0;
    }

    public void Update()
    {
        InvalidateVisual();
    }

    public void DrawCharAtPos(ushort xPos, ushort yPos, ushort c, bool inverted = false)
    {
        DrawChar((ushort)(xPos * _fontWidth), (ushort)(yPos * _fontHeight), c, inverted);
    }

    public void DrawChar(ushort x, ushort y, ushort c, bool inverted = false)
    {
        if (c >= _charCount)
            return;
        var h = _fontHeight;
        while (y < _height && h > 0)
        {
            var pRam = y * _wordWidth;
            var end = pRam + _wordWidth;
            pRam += x >> 4;
            var w = _fontWidth;
            while (pRam < end)
            {
                if (w < 16)
                    break;
                w -= 16;
                pRam++;
            }
            y++;
            h--;
        }
    }
    
    public override void Render(DrawingContext context)
    {
        var idx = 0;
        for (var y = 0; y < _height * _scale; y += _scale)
        {
            for (var x = 0; x < _width * _scale;)
            {
                var ramValue = _displayRam[idx++];
                for (var pixelIndex = 0; pixelIndex < 16; pixelIndex++)
                {
                    var color = (ramValue & 1) != 0 ? Brushes.Black : Brushes.White;
                    context.FillRectangle(color, new Rect(x, y, _scale, _scale));
                    ramValue >>= 1;
                    x += _scale;
                }
            }
        }
    }
}