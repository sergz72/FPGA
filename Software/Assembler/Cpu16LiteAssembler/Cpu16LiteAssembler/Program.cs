using Cpu16LiteAssembler;
using GenericAssembler;

List<string> sources = [];
var outputFormat = OutputFormat.Hex;

foreach (var arg in args)
{
    if (arg.StartsWith('-'))
    {
        switch (arg)
        {
            case "-x":
                outputFormat = OutputFormat.Hex;
                break;
            case "-b":
                outputFormat = OutputFormat.Bin;
                break;
            default:
                Usage();
                break;
        }
    }
    else
        sources.Add(arg);
}

if (sources.Count == 0)
    Usage();
else
{
    var compiler = new Cpu16Compiler(sources, outputFormat);
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