using PCapNGFileTransformer;

const int usbClock = 48;

if (args.Length != 3)
{
    Console.WriteLine("Usage: PCapNGFileTransformer <inputFile> <interfaceId> <outputFile>");
    return 1;
}

var inFile = args[0];
var interfaceId = uint.Parse(args[1]);
var outFile = args[2];

PacketBlock.UsbClock = usbClock;

var blockTypes = new IBlock[]
{
  new HeaderBlock(),
  new InterfaceDescriptionBlock(),
  new PacketBlock()
};
var blockMap = blockTypes.ToDictionary(b => b.Type, b => b);

var blocks = BuildBlocks(blockMap, File.ReadAllBytes(inFile));
ulong startTime = 0;
List<byte> output = BuildPause(50).ToList();
foreach (var block in blocks)
{
    if (block is PacketBlock pb && pb.InterfaceId == interfaceId)
    {
        if (startTime != 0)
        {
            var pauseTime = pb.Timestamp - startTime;
            if (pauseTime > 0x100)
                pauseTime = 0x100;
            output.AddRange(BuildPause(pauseTime));
        }
        output.AddRange(pb.BuildUsbPacket());
        Console.WriteLine(pb.ToString(0));
        startTime = pb.Timestamp;
    }
}
File.WriteAllBytes(outFile, output.ToArray());

return 0;

byte[] BuildPause(ulong us)
{
    return Enumerable.Repeat((byte)2, (int)us * usbClock).ToArray();
}

static List<IBlock> BuildBlocks(Dictionary<uint, IBlock> blockMap, byte[] data)
{
    var blocks = new List<IBlock>();
    var reader = new BinaryReader(new MemoryStream(data));
    while (reader.BaseStream.Position < reader.BaseStream.Length)
    {
        var blockType = reader.ReadUInt32();
        var blockLength = reader.ReadUInt32();
        if (!blockMap.TryGetValue(blockType, out var block))
            throw new Exception($"Unknown block type: {blockType}");
        var pos = reader.BaseStream.Position;
        blocks.Add(block.Create(reader, blockLength));
        reader.BaseStream.Seek(pos + blockLength - 12, SeekOrigin.Begin);
        var blockLength2 = reader.ReadUInt32();
        if (blockLength != blockLength2)
            throw new Exception($"Different block lengths: {blockLength} {blockLength2}");
    }
    return blocks;
}

internal interface IBlock
{
    uint Type { get; }
    IBlock Create(BinaryReader reader, uint blockLength);
}
