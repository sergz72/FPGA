using Cpu16Assembler;
using GenericAssembler;

List<string> sources = [];
var outputFileName = "a.out";
var outputFileNameExpected = false;
var outputFormat = OutputFormat.Hex;
var noDiv = true;
var noRem = true;
var noMul = true;

foreach (var arg in args)
{
    if (outputFileNameExpected)
    {
        outputFileName = arg;
        outputFileNameExpected = false;
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
                case "--hmul": // hardware mul
                    noMul = false;
                    break;
                case "--hdiv": // hardware div
                    noDiv = false;
                    break;
                case "--hrem": // hardware rem
                    noRem = false;
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
    var compiler = new Cpu16Compiler(sources, outputFileName, outputFormat, noDiv, noRem, noMul);
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
    Console.WriteLine("Usage: Cpu16Assembler [-o outputFileName] sources");
}