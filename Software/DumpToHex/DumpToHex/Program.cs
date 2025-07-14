const string contentsLineStart = "Contents of section ";
const string codeFileName = "code.hex";
const string dataFileNamePrefix = "data";
const string dataFileNameSuffix = ".hex";

string? prevCode = null;

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
    
    var parts = line.Split(' ');
    var spaces = 0;
    var idx = 0;
    var lines = new List<string>();
    foreach (var part in parts)
    {
        if (part.Length == 0)
        {
            spaces++;
            if (spaces > 1)
                break;
            continue;
        }
        if (idx > 0)
            lines.Add(part.PadRight(8, '0'));
        idx++;
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
        }
        else
        {
            prevCode = code;
            return null;
        }
    }
    return code + " // " + parts[0].PadLeft(8) + " " + parts[2];
}
