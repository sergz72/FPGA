using System;
using System.Globalization;
using System.IO;
using System.Linq;
using Avalonia;
using Avalonia.Controls;
using Avalonia.Media;

namespace LcdTest;

public sealed class TwoColorLcd: Control
{
    private const int FontRomHeaderSize = 3;
    
    private int _width, _height, _scale, _wordWidth;
    private ushort[] _displayRam = [];
    private ushort[] _fontRom = [];
    private ushort _charCount, _fontWidth, _fontHeight, _fontMask;
    
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
        _fontRom = lines.Select(l => ushort.Parse(l.Split("//")[0], NumberStyles.HexNumber)).ToArray();
        _fontWidth = _fontRom[0];
        if (_fontWidth > 16)
            throw new ArgumentException("Font width must be <= 16");
        _fontHeight = _fontRom[1];
        _charCount = _fontRom[2];
        if (_fontRom.Length != _charCount * _fontHeight + FontRomHeaderSize)
            throw new ArgumentException("Wrong fontRam length");
        _fontMask = (ushort)((1 << _fontWidth) - 1);
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
        var mapped = c switch
        {
            ' ' => (ushort)10,
            '.' => (ushort)11,
            'H' => (ushort)12,
            'V' => (ushort)13,
            'm' => (ushort)14,
            'z' => (ushort)15,
            >= '0' and <= '9' => (ushort)(c - '0'),
            _ => c
        };
        DrawChar((ushort)(xPos * _fontWidth), (ushort)(yPos * _fontHeight), mapped, inverted);
    }

    public void DrawChar(ushort x, ushort y, ushort c, bool inverted = false)
    {
        if (c >= _charCount)
            return;
        var pFontRom = c * _fontHeight + FontRomHeaderSize;
        var h = _fontHeight;
        var pRamStart = y * _wordWidth;
        while (pRamStart < _displayRam.Length && h > 0)
        {
            var end = pRamStart + _wordWidth;
            var pRam = pRamStart + (x >> 4);
            if (pRam >= end)
                return;
            var fontData = _fontRom[pFontRom];
            if (inverted)
                fontData = (ushort)(~fontData & _fontMask);
            var displayData = _displayRam[pRam];
            var offset = x & 0x0f;
            var bits = 16 - offset;
            var tempFontData = (ushort)(fontData << offset);
            var mask = (ushort)(_fontMask << offset);
            tempFontData &= mask;
            displayData &= (ushort)~mask;
            displayData |= tempFontData;
            _displayRam[pRam] = displayData;
            if (bits < _fontWidth)
            {
                pRam++;
                if (pRam < end)
                {
                    displayData = _displayRam[pRam];
                    tempFontData = (ushort)(fontData >> bits);
                    mask = (ushort)(_fontMask >> bits);
                    displayData &= (ushort)~mask;
                    displayData |= tempFontData;
                    _displayRam[pRam] = displayData;
                }
            }
            pRamStart += _wordWidth;
            pFontRom++;
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