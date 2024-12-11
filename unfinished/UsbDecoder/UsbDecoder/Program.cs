if (args.Length != 2 || (args[1] != "single" && args[1] != "multi"))
{
    Console.WriteLine("Usage: UsbDecoder fileName [single|multi]");
    return 1;
}

var single = args[1] == "single";

var data = File.ReadAllBytes(args[0]);

var decoder = new UsbDecoder.UsbDecoder();

foreach (var b in data)
{
    var samples = BuildSamples(b);
    foreach (var sample in samples)
        decoder.Process(sample);
}

return 0;

byte[] BuildSamples(byte b)
{
    if (single)
        return [b];
    return [(byte)(b & 3), (byte)((b >> 2) & 3), (byte)((b >> 4) & 3), (byte)((b >> 6) & 3)];
}
