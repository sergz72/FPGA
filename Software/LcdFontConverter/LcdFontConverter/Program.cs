using System.Globalization;

// uses this URL to get fonts : https://rop.nl/truetype2gfx/

var lines = File.ReadAllLines(args[0]);

var lineNo = LoadBitmaps(out var bitmaps);
var glyphs = LoadGlyphs();

var maxHeight = glyphs.Max(x => x.Height);
var maxWidth = glyphs.Max(x => x.Width);

PrintGlyphs('0', '1', '2', '3', '4', '5', '6', '7', '8', '9', ' ', '.', 'H', 'V', 'm', 'z');

return;

void PrintGlyphs(params char[] chars)
{
    Console.WriteLine($"{maxWidth:X4} // font width");
    Console.WriteLine($"{maxHeight:X4} // font height");
    Console.WriteLine($"{chars.Length:X4} // font chars count");

    var wordCount = 3;
    
    foreach (var c in chars)
    {
        var gl = glyphs[c - ' '];
        var idx = gl.BitmapOffset;
        var bits = gl.Height * gl.Width;
        var mask = (1 << gl.Width) - 1;
        var yo = gl.YOffset + maxHeight - 3;
        
        var h = 0;
        while (h < yo)
        {
            Console.WriteLine($"0000 // {h:d2} 0000000000000000");
            wordCount++;
            h++;
        }

        byte b = 0;
        var value = 0;
        var bit = 0;
        while (bits > 0)
        {
            if (bit != 0 && bit % gl.Width == 0)
            {
                value <<= gl.XOffset;
                Console.WriteLine($"{value:X4} // {h:d2} {value:b16}");
                wordCount++;
                h++;
                value = 0;
            }
            if ((bit & 7) == 0)
                b = bitmaps[idx++];
            value >>= 1;
            if ((b & 0x80) != 0)
                value |= 1 << gl.XOffset + gl.Width - 1;
            b <<= 1;
            bit++;
            bits--;
        }
        value <<= gl.XOffset;
        Console.WriteLine($"{value:X4} // {h:d2} {value:b16}");
        wordCount++;
        h++;

        while (h < maxHeight)
        {
            Console.WriteLine($"0000 // {h:d2} 0000000000000000");
            wordCount++;
            h++;
        }
    }
    Console.Error.WriteLine(wordCount);
}

int LoadBitmaps(out List<byte> bmps)
{
    var i = 1;
    bmps = [];
    while (i < lines.Length)
    {
        if (lines[i].Length == 0)
            break;
        var parts = lines[i++].Split(new char[]{',', ' ', '{', '}', ';'}, StringSplitOptions.RemoveEmptyEntries);
        bmps.AddRange(parts.Select(s => byte.Parse(s.Trim()[2..], NumberStyles.HexNumber)));
    }

    return i + 2;
}

List<Glyph> LoadGlyphs()
{
    var glyphList = new List<Glyph>();
    while (lineNo < lines.Length)
    {
        if (lines[lineNo].Length == 0)
            break;
        var parts = lines[lineNo].Split(new char[]{',', ' ', '{', '}', ';'}, StringSplitOptions.RemoveEmptyEntries);
        if (parts.Length < 6)
            throw new FormatException($"Invalid glyph line format: {lines[lineNo]}");
        lineNo++;
        glyphList.Add(new Glyph(
            int.Parse(parts[0]),
            int.Parse(parts[1]),
            int.Parse(parts[2]),
            int.Parse(parts[3]),
            int.Parse(parts[4]),
            int.Parse(parts[5])
        ));
    }
    return glyphList;
}

internal record Glyph(int BitmapOffset, int Width, int Height, int XAdvance, int XOffset, int YOffset);
