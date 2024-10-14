using GenericAssembler;
using Tiny16Assembler;

List<string> sources = [];
var outputFileName = "a.out";
var outputFileNameExpected = false;
var outputFormat = OutputFormat.Hex;
var noDiv32 = true;
var noRem32 = true;
var noDiv16 = true;
var noRem16 = true;
var noMul = true;
var arch = "v3";
var archExpected = false;

foreach (var arg in args)
{
    if (outputFileNameExpected)
    {
        outputFileName = arg;
        outputFileNameExpected = false;
    }
    else if (archExpected)
    {
        arch = arg;
        archExpected = false;
    }
    else
    {
        if (arg.StartsWith('-'))
        {
            switch (arg)
            {
                case "-o":
                    outputFileNameExpected = true;
                    break;
                case "-x":
                    outputFormat = OutputFormat.Hex;
                    break;
                case "-b":
                    outputFormat = OutputFormat.Bin;
                    break;
                case "--arch":
                    archExpected = true;
                    break;
                case "--hmul": // hardware mul
                    noMul = false;
                    break;
                case "--hdiv32": // hardware div 32 / 16
                    noDiv32 = false;
                    break;
                case "--hrem32": // hardware rem 32 % 16
                    noRem32 = false;
                    break;
                case "--hdiv16": // hardware div 16 / 16
                    noDiv16 = false;
                    break;
                case "--hrem16": // hardware rem 16 / 16
                    noRem16 = false;
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

if (sources.Count == 0 || outputFileNameExpected)
    Usage();
else
{
    GenericCompiler compiler = arch switch
    {
        "v2" => new Tiny16V2Compiler(sources, outputFileName, outputFormat, noDiv32, noRem32, noMul, noDiv16, noRem16),
        "v3" => new Tiny16V3Compiler(sources, outputFileName, outputFormat),
        _ => throw new Exception($"Unknown architecture {arch}")
    };
    try
    {
        compiler.Compile();
    }
    catch (Exception e)
    {
        Console.WriteLine(e.Message);
    }
}

return;

void Usage()
{
    Console.WriteLine("Usage: Tiny16Assembler [-o outputFileName] [- x outputFormat] [--arch arch] sources");
}