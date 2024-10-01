namespace Tiny32MicrocodeGenerator;

internal static class DecoderCodeGenerator
{
    private const int codeLength = 2048;

    internal static void GenerateCode()
    {
        var lines = new List<string>();
        var r = new Random();
        for (var i = 0; i < codeLength; i++)
            lines.Add(r.Next(255).ToString("X2"));
        File.WriteAllLines("decoder.mem", lines);
    }
}