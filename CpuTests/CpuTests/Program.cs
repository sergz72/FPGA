using System.Diagnostics;
using System.Text.Json;

if (args.Length != 1)
{
    Console.WriteLine("Usage: CpuTests configurationFileName");
    return;
}

try
{
    var text = File.ReadAllText(args[0]);
    var config = JsonSerializer.Deserialize<Configuration>(text);
    if (config == null || config.TestsDir == "" || config.BuildCommand == "" || config.SimulatorCommand == "" ||
        config.Ok == "")
    {
        Console.WriteLine("Incorrect configuration file");
        return;
    }
    var baseDir = Path.GetDirectoryName(args[0]) ?? throw new Exception("GetDirectoryName returned null");
    if (baseDir != "")
        Directory.SetCurrentDirectory(baseDir);
    var files = Directory.GetFiles(config.TestsDir);
    var testCount = 0;
    var failedTests = new List<string>();
    foreach (var file in files)
    {
        testCount++;
        Console.WriteLine($"Testing {file} ...");
        Console.WriteLine("Building...");
        RunCommand(config.BuildCommand, file);
        Console.WriteLine("Running simulator...");
        var output = RunCommand(config.SimulatorCommand);
        Console.WriteLine("Analysing simulator output...");
        string? message = null;
        foreach (var line in output)
        {
            if (config.Error != "" && line.Contains(config.Error))
            {
                message = $"Error: {line}";
                failedTests.Add(file);
                break;
            }

            if (line.Contains(config.Flag))
            {
                if (line.Contains(config.Ok))
                    message = $"Test passed: {line}";
                else
                {
                    message = $"Test failed: {line}";
                    failedTests.Add(file);
                }
                break;
            }
        }

        if (message == null)
        {
            failedTests.Add(file);
            Console.WriteLine("Test failed: flag wasn't found.");
        }
        else
            Console.WriteLine(message);
    }
    Console.WriteLine($"Total tests: {testCount}, Failed tests: {failedTests.Count}");
    Console.Write("Failed tests:");
    foreach (var test in failedTests)
        Console.Write(" " + test);
    Console.WriteLine();
}
catch (Exception ex)
{
    Console.WriteLine(ex);
}

return;

List<string> RunCommand(string path, string parameter = "")
{
    var p = new Process();
    p.StartInfo.FileName = path;
    p.StartInfo.Arguments = parameter;
    p.StartInfo.UseShellExecute = false;
    p.StartInfo.RedirectStandardOutput = true;
    p.StartInfo.RedirectStandardError = true;
    p.Start();
    var lines = new List<string>();
    for (;;)
    {
        var line = p.StandardOutput.ReadLine();
        if (line != null)
            lines.Add(line);
        else
            break;
    }
    for (;;)
    {
        var line = p.StandardError.ReadLine();
        if (line != null)
            lines.Add(line);
        else
            break;
    }
    p.WaitForExit();
    if (p.ExitCode != 0)
        throw new Exception($"{path} {parameter} failed with exit code {p.ExitCode}");
    
    return lines;
}

internal record Configuration(string TestsDir, string BuildCommand, string SimulatorCommand, string Flag,
                                string Error, string Ok);
                                