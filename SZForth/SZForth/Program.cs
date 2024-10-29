using SZForth;

List<string> sources = [];
var configFileName = "";
var configFileNameExpected = false;
var vmConfigFileName = "";
var vmConfigFileNameExpected = false;
var bits = 16;
var bitsExpected = false;
var onlyCompile = false;

foreach (var arg in args)
{
    if (configFileNameExpected)
    {
        configFileName = arg;
        configFileNameExpected = false;
    }
    else if (vmConfigFileNameExpected)
    {
        vmConfigFileName = arg;
        vmConfigFileNameExpected = false;
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
                case "--config":
                    configFileNameExpected = true;
                    break;
                case "--vmconfig":
                    vmConfigFileNameExpected = true;
                    break;
                case "-c":
                    onlyCompile = true;
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

if (sources.Count == 0 || configFileNameExpected || bitsExpected || vmConfigFileNameExpected || configFileName == "")
    return Usage();
else
{
    var config = ParsedConfiguration.ReadConfiguration(configFileName);
    var compiler = new ForthCompiler(config, sources, bits);
    try
    {
        var result = compiler.Compile();
        if (onlyCompile)
            BuildOutputFiles(config, result);
        else
            new ForthVM(config, vmConfigFileName, result).Run();
    }
    catch (Exception e)
    {
        Console.WriteLine(e.Message);
        Console.WriteLine(e.StackTrace);
        return 1;
    }
}

return 0;

void BuildOutputFiles(ParsedConfiguration config, CompilerResult result)
{
    var format = bits == 16 ? "X4" : "X8";
    BuildOutputFile(config.Code.FileName, result.CodeInstructions, format);
    BuildOutputFile(config.Data.FileName, result.DataInstructions, format);
    BuildOutputFile(config.RoData.FileName, result.RoDataInstructions, format);
}

void BuildOutputFile(string fileName, List<Instruction> instructions, string format)
{
    if (instructions.Count == 0)
    {
        if (File.Exists(fileName))
            File.Delete(fileName);
    }
    else
        File.WriteAllLines(fileName, BuildCodeLines(instructions, format));
}

List<string> BuildCodeLines(List<Instruction> instructions, string format)
{
    var result = new List<string>();
    foreach (var instruction in instructions)
    {
        var codeLines = instruction
            .BuildCodeLines(format)
            .ToList();
        result.AddRange(codeLines);
    }
    return result;
}

int Usage()
{
    Console.WriteLine("Usage: SZForth -c configFileName [-c] sources");
    return 1;
}
