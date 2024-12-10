using System.Diagnostics;
using System.IO.Compression;
using SigrokFileTransformer;

if (args.Length < 5)
{
    Console.WriteLine("Usage: SigrokFileTransformer <inputFile> <outputFile> deviceId <sampleRate> <signal1> [<signal2> <...> <signalN>]");
    return 1;
}

var archiveName = args[0];
var outputFile = args[1];
var deviceId = int.Parse(args[2]);
var sampleRate = int.Parse(args[3]);
var signals = args.Skip(4).ToArray();

using var archive = ZipFile.Open(archiveName, ZipArchiveMode.Read);
var metadataFile = archive.GetEntry("metadata") ?? throw new FileNotFoundException("Metadata file was not found");

var stopwatch = new Stopwatch();
stopwatch.Start();
var device = BuildMetadata();
stopwatch.Stop();
Console.WriteLine($"BuildMetadata took {stopwatch.Elapsed.Seconds}.{stopwatch.Elapsed.Milliseconds:000} s");

var signalIds = signals.Select(s => device.Probes[s]).ToArray();

stopwatch.Reset();
stopwatch.Start();
var samples = BuildSamples(archive, device.CaptureFilePrefix, device.TotalProbes);
stopwatch.Stop();
Console.WriteLine($"BuildSamples took {stopwatch.Elapsed.Seconds}.{stopwatch.Elapsed.Milliseconds:000} s");

stopwatch.Reset();
stopwatch.Start();
var converted = ConvertSamples(samples, device.SampleRate, sampleRate);
stopwatch.Stop();
Console.WriteLine($"ConvertSamples took {stopwatch.Elapsed.Seconds}.{stopwatch.Elapsed.Milliseconds:000} s");

CreateOutputFile(converted, signalIds, outputFile);

return 0;

static void CreateOutputFile(int[] samples, int[] signalIds, string outputFile)
{
    using var file = File.OpenWrite(outputFile);
    foreach (var sample in samples)
        file.WriteByte(BuildSampleByte(sample, signalIds));
}

static byte BuildSampleByte(int value, int[] signalIds)
{
    var result = 0;
    var bit = 1;
    foreach (var signalId in signalIds)
    {
        if ((value & (1 << (signalId - 1))) != 0)
            result |= bit;
        bit <<= 1;
    }
    return (byte)result;
}

static int[] ConvertSamples(List<int> samples, int deviceSampleRate, int sampleRate)
{
    var length = (long)samples.Count * sampleRate / deviceSampleRate;
    var result = new int[length];
    for (long i = 0; i < length; i++)
    {
        var sampleId = i * deviceSampleRate / sampleRate;
        if (sampleId >= samples.Count)
            sampleId = samples.Count - 1;
        result[i] = samples[(int)sampleId];
    }
    return result;
}

static List<int> BuildSamples(ZipArchive archive, string deviceCaptureFilePrefix, int deviceTotalProbes)
{
    var sampleFileId = 1;
    var samples = new List<int>();
    
    for (;;)
    {
        var fileName = deviceCaptureFilePrefix + "-" + sampleFileId;
        var sampleFile = archive.GetEntry(fileName);
        if (sampleFile == null)
            return samples;
        samples.AddRange(BuildFileSamples(sampleFile, deviceTotalProbes));
        sampleFileId++;
    }
}

static List<int> BuildFileSamples(ZipArchiveEntry sampleFile, int deviceTotalProbes)
{
    using var stream = sampleFile.Open();
    var data = new byte[sampleFile.Length];
    stream.ReadExactly(data, 0, data.Length);
    stream.Close();
    using var mstream = new MemoryStream(data);
    using var reader = new BinaryReader(mstream);
    var samples = new List<int>();
    var position = 0;
    while (position < sampleFile.Length)
    {
        switch (deviceTotalProbes)
        {
            case 8:
                samples.Add(reader.ReadByte());
                position++;
                break;
            case 16:
                samples.Add(reader.ReadInt16());
                position += 2;
                break;
            case 32:
                samples.Add(reader.ReadInt32());
                position += 4;
                break;
            default:
                throw new FormatException("Unsupported total probes value");
        }
    }
    return samples;
}

Device BuildMetadata()
{
    using var stream = metadataFile.Open();
    using var reader = new StreamReader(stream);
    var lines = reader.ReadToEnd().Split(Environment.NewLine.ToCharArray(), StringSplitOptions.RemoveEmptyEntries);
    var ini = new IniFile(lines);
    var deviceData = ini.Sections["device " + deviceId];
    return new Device(deviceData["capturefile"], int.Parse(deviceData["total probes"]),
                        ParseSampleRate(deviceData["samplerate"]), BuildProbes(deviceData));
}

static Dictionary<string, int> BuildProbes(Dictionary<string, string> deviceData)
{
    return deviceData
        .Where(kvp => kvp.Key.StartsWith("probe"))
        .ToDictionary(kvp => kvp.Value, kvp => int.Parse(kvp.Key[5..]));
}

static int ParseSampleRate(string s)
{
    var parts = s.Split(' ', StringSplitOptions.RemoveEmptyEntries);
    if (parts.Length > 2)
        throw new FormatException("Invalid sample rate format");
    var multiplier = 1;
    if (parts.Length == 2)
    {
        switch (parts[1])
        {
            case "MHz": multiplier = 1000000; break;
            default: throw new FormatException("Invalid sample rate");
        }
    }
    return int.Parse(parts[0]) * multiplier;
}

internal record Device(string CaptureFilePrefix, int TotalProbes, int SampleRate, Dictionary<string, int> Probes);
