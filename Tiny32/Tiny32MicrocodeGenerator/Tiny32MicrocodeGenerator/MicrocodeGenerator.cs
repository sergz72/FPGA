namespace Tiny32MicrocodeGenerator;

internal static class MicrocodeGenerator
{
    private const int codeLength = 256;

    internal static void GenerateCode()
    {
        var lines = new List<string>();
        var r = new Random();
        for (var i = 0; i < codeLength; i++)
            lines.Add(r.Next((1 << 22) - 1).ToString("X6"));
        File.WriteAllLines("microcode.mem", lines);
    }
}