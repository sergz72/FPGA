using CCompiler;

List<string> sources = [];
var outputFileName = "a.asm";
var outputFileNameExpected = false;
var architecture = "Cpu16Lite";
var architectureExpected = false;
var includePathExpected = false;
var includePaths = new List<string>();
var defines = new Dictionary<string, string>();
var onlyPreprocess = false;

foreach (var arg in args)
{
    if (outputFileNameExpected)
    {
        outputFileName = arg;
        outputFileNameExpected = false;
    }
    else if (architectureExpected)
    {
        architecture = arg;
        architectureExpected = false;
    }
    else if (includePathExpected)
    {
        includePaths.Add(Path.GetFullPath(arg));
        includePathExpected = false;
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
                case "-a":
                    architectureExpected = true;
                    break;
                case "-I":
                    includePathExpected = true;
                    break;
                case "-E":
                    onlyPreprocess = true;
                    break;
                default:
                    if (arg.StartsWith("-D"))
                        ParseDefine(arg[2..]);
                    else
                        Usage();
                    break;
            }
        }
        else
            sources.Add(arg);
    }
}

if (sources.Count == 0 || outputFileNameExpected || architectureExpected || includePathExpected)
    Usage();
else
{
    var preprocessor = new Preprocessor(includePaths, defines);
    var compiler = new CCompiler.CCompiler(sources, preprocessor, architecture);
    try
    {
        compiler.Compile(onlyPreprocess);
        if (!onlyPreprocess)
        {
            var code = compiler.GenerateCode();
            File.WriteAllLines(outputFileName, code);
        }
    }
    catch (Exception e)
    {
        Console.WriteLine(e);
    }
}

return;

void ParseDefine(string define)
{
    var parts = define.Split('=');
    defines.Add(parts[0], parts.Length == 1 ? "" : parts[1]);
}

void Usage()
{
    Console.WriteLine("Usage: CCompiler [-o outputFileName] [-a architecture] sources");
}
