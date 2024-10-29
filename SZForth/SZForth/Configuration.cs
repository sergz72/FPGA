using System.Globalization;
using System.Text.Json;

namespace SZForth;

internal record Section(string FileName, string Address, string Size, string EntryPoint, string[] IsrHandlers);

internal record Configuration(Section Code, Section Data, Section RoData);

internal record ParsedSection(string FileName, uint Address, uint Size, string EntryPoint, string[] IsrHandlers)
{
    internal ParsedSection(Section section, uint address, uint size):
        this(section.FileName, address, size, section.EntryPoint, section.IsrHandlers)
    {
    }
}

internal record ParsedConfiguration(ParsedSection Code, ParsedSection Data, ParsedSection RoData)
{
    internal static ParsedConfiguration ReadConfiguration(string fileName)
    {
        using var stream = File.OpenRead(fileName);
        var config = JsonSerializer.Deserialize<Configuration>(stream);
        if (config == null)
            throw new CompilerException("configuration file parse error");
        if (config.Code.EntryPoint == "" || config.Code.FileName == "" || !ParseSize(config.Code.Size, out uint codeSize))
            throw new CompilerException("invalid code segment configuration");
        if (!ParseAddress(config.Data.Address, out var dataAddress) || config.Data.FileName == "" ||
            !ParseSize(config.Data.Size, out uint dataSize))
            throw new CompilerException("invalid data segment configuration");
        if (!ParseAddress(config.RoData.Address, out var roDataAddress) || config.RoData.FileName == "" ||
            !ParseSize(config.RoData.Size, out uint roDataSize))
            throw new CompilerException("invalid data segment configuration");
        return new ParsedConfiguration(new ParsedSection(config.Code, 0, codeSize),
                                        new ParsedSection(config.Data, dataAddress, dataSize),
                                        new ParsedSection(config.RoData, roDataAddress, roDataSize));
    }

    private static bool ParseAddress(string sAddress, out uint address)
    {
        var style = NumberStyles.Integer;
        var start = 0;
        if (sAddress.StartsWith("0x"))
        {
            style = NumberStyles.HexNumber;
            start = 2;
        }
        return uint.TryParse(sAddress[start..], style, NumberFormatInfo.InvariantInfo, out address);
    }

    private static bool ParseSize(string sSize, out uint size)
    {
        uint multiplier = 1;
        if (sSize.EndsWith('K'))
        {
            sSize = sSize[..^1];
            multiplier = 1024;
        }
        var result = uint.TryParse(sSize, out var s);
        size = s * multiplier;
        return result;
    }
}
