using SZForth;

List<string> sources = [];
var configFileName = "";
var configFileNameExpected = false;
var bits = 16;
var bitsExpected = false;

foreach (var arg in args)
{
    if (configFileNameExpected)
    {
        configFileName = arg;
        configFileNameExpected = false;
    }
    else if (bitsExpected)
    {
        switch (arg)
        {
            case "16":
                bits = 16;
                break;
            case "32":
                bits = 32;
                break;
            default:
                Console.WriteLine("Invalid bits value");
                return 1;
        }
        bitsExpected = false;
    }
    else
    {
        if (arg.StartsWith('-'))
        {
            switch (arg)
            {
                case "-c":
                    configFileNameExpected = true;
                    break;
                case "-b":
                    bitsExpected = true;
                    break;
                default:
                    Usage();
                    break;
            }
        }
        else
            sources.Add(arg);
    }
}

if (sources.Count == 0 || configFileNameExpected || bitsExpected || configFileName == "")
    return Usage();
else
{
    var config = ParsedConfiguration.ReadConfiguration(configFileName);
    var compiler = new ForthCompiler(config, sources, bits);
    try
    {
        var result = compiler.Compile();
        var pcFormat = bits == 16 ? "X4" : "X8";
        BuildOutputFiles(config, result, pcFormat);
        BuldMapFile(config, compiler, pcFormat);
    }
    catch (Exception e)
    {
        Console.WriteLine(e.Message);
        Console.WriteLine(e.StackTrace);
        return 1;
    }
}

return 0;

void BuldMapFile(ParsedConfiguration config, ForthCompiler compiler, string pcFormat)
{
    if (config.MapFileName != null)
    {
        var contents = compiler.BuildMapFile(pcFormat);
        File.WriteAllLines(config.MapFileName, contents);
    }
}

void BuildOutputFiles(ParsedConfiguration config, CompilerResult result, string pcFormat)
{
    var format = bits == 16 ? "X2" : "X4";
    BuildOutputFile(config.Code.FileName, result.CodeInstructions, format, pcFormat, 0);
    BuildOutputFile(config.Data.FileName, result.DataInstructions, pcFormat, pcFormat, (int)config.Data.Address);
    BuildOutputFile(config.RoData.FileName, result.RoDataInstructions, pcFormat, pcFormat, (int)config.RoData.Address);
}

void BuildOutputFile(string fileName, List<Instruction> instructions, string format, string pcFormat, int pc)
{
    if (instructions.Count == 0)
    {
        if (File.Exists(fileName))
            File.Delete(fileName);
    }
    else
        File.WriteAllLines(fileName, BuildCodeLines(instructions, format, pcFormat, pc));
}

List<string> BuildCodeLines(List<Instruction> instructions, string format, string pcFormat, int pc)
{
    var result = new List<string>();
    foreach (var instruction in instructions)
    {
        var codeLines = instruction
            .BuildCodeLines(format, pcFormat, pc)
            .ToList();
        result.AddRange(codeLines);
        pc += codeLines.Count;
    }
    return result;
}

int Usage()
{
    Console.WriteLine("Usage: SZForth -c configFileName [-b 16|32] sources");
    return 1;
}
