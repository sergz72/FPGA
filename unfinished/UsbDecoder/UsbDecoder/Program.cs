if (args.Length != 1)
{
    Console.WriteLine("Usage: UsbDecoder fileName");
    return 1;
}

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
    return [b];
}
