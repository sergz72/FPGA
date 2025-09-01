using System.Text;

const string contentsLineStart = "Contents of section ";
const string codeFileName = "code.hex";
const string flashHexFileName = "flash.hex";
const string flashBinFileName = "flash.bin";
const string dataFileNamePrefix = "data";
const string dataFileNameSuffix = ".hex";

string? prevCode = null;
string? prevLine = null;

var generateFlash = args.Length == 4 && args[3] == "generate_flash";

if (args.Length != 3 && (args.Length != 4 || !generateFlash))
{
    Console.WriteLine("Usage: DumpToHex data_split_size asm_dump_file data_dump_file [generate_flash]");
    return;
}

if (!int.TryParse(args[0], out var dataSplitSize) || dataSplitSize < 2 || (dataSplitSize & 1) != 0)
{
    Console.WriteLine("Wrong data_split_size.");
    return;
}

var codeFileLines = File.ReadAllLines(args[1]);
var dataFileLines = File.ReadAllLines(args[2]);
var start = false;

var codeLines = codeFileLines
    .Select(BuildCodeLine)
    .Where(l => l != null)
    .Select(s => s!)
    .ToList();

if (prevCode != null)
    codeLines.Add(BuildCodeLine("last_line: 0000 last line")!);

start = false;

var roDataLines = dataFileLines
    .SelectMany(l => BuildDataLines(l, ".rodata", ".srodata"))
    .ToList();

codeLines.AddRange(roDataLines);
File.WriteAllLines(codeFileName, codeLines);
if (generateFlash)
{
    File.WriteAllLines(flashHexFileName, BuildFlashHexFile());
    File.WriteAllBytes(flashBinFileName, BuildFlashBinFile());
}

start = false;

var dataLines = dataFileLines
    .SelectMany(l => BuildDataLines(l, ".data", ".sdata"))
    .ToList();
if (dataLines.Count == 0) return;

var count = dataLines[0].Length / dataSplitSize;
if (count == 1)
{
    File.WriteAllLines(dataFileNamePrefix + dataFileNameSuffix, dataLines);
    return;
}

for (var idx = 1; idx <= count; idx++)
{
    var from = (idx - 1) * dataSplitSize;
    var to = from + dataSplitSize;
    var dataLinesSplitted = dataLines
        .Select(l => l[from..to])
        .ToList();
    File.WriteAllLines($"{dataFileNamePrefix}{idx}{dataFileNameSuffix}", dataLinesSplitted);
}

return;

string RevertBytes(string part)
{
    var sb = new StringBuilder();

    for (var i = part.Length - 2; i >= 0; i -= 2)
        sb.Append(part.AsSpan(i, 2));

    return sb.ToString().PadRight(8, '0');
}

List<string> BuildDataLines(string line, params string[] sections)
{
    if (line.Length == 0)
        return [];

    if (line.StartsWith(contentsLineStart))
    {
        var l = line[contentsLineStart.Length..];
        start = sections.Any(s => l.StartsWith(s));
        return [];
    }

    if (!start) return [];
    
    var parts = line.Trim().Split(' ');
    if (parts.Length < 3)
        return [];
    var lines = new List<string>();
    foreach (var part in parts[1..])
    {
        if (part.Length == 0)
            break;
        lines.Add(RevertBytes(part));
    }
    return lines;
}

string? BuildCodeLine(string line)
{
    if (line.Length == 0)
        return null;
    
    if (line.StartsWith("Disassembly of section "))
    {
        start = true;
        return null;
    }

    if (!start) return null;
    
    var parts = line.Split([' ', '\t'], 3, StringSplitOptions.RemoveEmptyEntries);
    if (parts.Length != 3)
        return "// " + line;
    var code = parts[1];
    if (code.Length == 4) // 16 bit something
    {
        if (prevCode != null)
        {
            code += prevCode;
            prevCode = null;
            prevLine = null;
        }
        else
        {
            prevCode = code;
            prevLine = line;
            return null;
        }
    }
    else if (prevCode != null)
    {
        var temp = code[..4];
        code = code[4..8] + prevCode;
        prevCode = temp;
        prevLine = line;
    }
    return (prevLine == null ? "" : "// " + prevLine + "\n") + code + " // " + parts[0].PadLeft(8) + " " + parts[2];
}

List<string> BuildFlashLines(string code)
{
    var chars = code.ToCharArray();
    var list = new List<string>();
    for (var i = chars.Length - 2; i >= 0; i -= 2)
    {
        list.Add(chars[i].ToString());
        list.Add(chars[i+1].ToString());
    }
    return list;
}

List<byte> BuildFlashBytes(string code)
{
    var list = new List<byte>();
    for (var i = code.Length - 2; i >= 0; i -= 2)
        list.Add(Convert.ToByte(code.Substring(i, 2), 16));
    return list;
}

IEnumerable<string> BuildFlashHexFile()
{
    var lines = codeLines
        .Select(line => line.Split("//", 2))
        .Where(parts => parts.Length != 0 && parts[0].Trim().Length != 0)
        .SelectMany(parts => BuildFlashLines(parts[0].Trim()));
    return lines;
}

byte[] BuildFlashBinFile()
{
    var bytes = codeLines
        .Select(line => line.Split("//", 2))
        .Where(parts => parts.Length != 0 && parts[0].Trim().Length != 0)
        .SelectMany(parts => BuildFlashBytes(parts[0].Trim()));
    return bytes.ToArray();
}
