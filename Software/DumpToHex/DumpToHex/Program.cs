using System.Text;

const string contentsLineStart = "Contents of section ";
const string codeFileName = "code.hex";
const string dataFileNamePrefix = "data";
const string dataFileNameSuffix = ".hex";

string? prevCode = null;
string? prevLine = null;

if (args.Length != 3)
{
    Console.WriteLine("Usage: DumpToHex data_split_size asm_dump_file data_dump_file");
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

start = false;

var roDataLines = dataFileLines
    .SelectMany(l => BuildDataLines(l, ".rodata", ".srodata"))
    .ToList();

codeLines.AddRange(roDataLines);
File.WriteAllLines(codeFileName, codeLines);

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
