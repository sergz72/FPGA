using JavaCPUAssembler;

if (args.Length < 2)
{
    Usage();
    return 1;
}

var compiler = new JavaCPUCompiler(args.ToList());
try
{
    compiler.Compile();
}
catch (Exception e)
{
    Console.WriteLine(e.Message);
}

return 0;

void Usage()
{
    Console.WriteLine("Usage: JavaCPUAssembler configFileName sources");
}