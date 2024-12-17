namespace PCapNGFileTransformer;

internal class PacketBlock: IBlock
{
    public uint Type => 6;

    private static int _usbClock;
    public static int UsbClock
    {
        get => _usbClock;
        set
        {
            _usbClock = value;
            _state = 2;
            _prev = false;
            _sync = BuildByte(1);
            _packetEnd = new byte[2*UsbClock/12];
            for (var i = 0; i < _packetEnd.Length; i++)
                _packetEnd[i] = 0;
        }
    }

    public readonly uint InterfaceId;
    public readonly ulong Timestamp;
    public readonly uint CapturedPacketLength;
    public readonly uint OriginalPacketLength;
    public readonly byte[] PacketData;

    private static byte[] _sync = [], _packetEnd = [];

    private static byte _state;
    private static bool _prev;
    
    internal PacketBlock()
    {
        PacketData = [];
    }
    
    public IBlock Create(BinaryReader reader, uint blockLength)
    {
        return new PacketBlock(reader);
    }

    private PacketBlock(BinaryReader reader)
    {
        InterfaceId = reader.ReadUInt32();
        ulong timestampUpper = reader.ReadUInt32();
        ulong timestampLower = reader.ReadUInt32();
        Timestamp = (timestampUpper << 32) | timestampLower;
        CapturedPacketLength = reader.ReadUInt32();
        OriginalPacketLength = reader.ReadUInt32();
        PacketData = reader.ReadBytes((int)CapturedPacketLength);
    }

    public string ToString(ulong startTime)
    {
        var data = BitConverter.ToString(PacketData);
        return $"Packet block interfaceId={InterfaceId} us={Timestamp-startTime} capturedPacketLength={CapturedPacketLength}" +
               $" originalPacketLength={OriginalPacketLength}\nData: {data}";
    }

    public List<byte> BuildUsbPacket()
    {
        var result = new List<byte>();
        result.AddRange(_sync);
        result.AddRange(BuildPacket());
        result.AddRange(_packetEnd);
        return result;
    }

    private IEnumerable<byte> BuildPacket()
    {
        _state = 2;
        _prev = false;
        return PacketData.SelectMany(BuildByte);
    }
    
    private static byte[] BuildByte(byte value)
    {
        var result = new byte[8 * UsbClock / 12];
        var idx = 0;
        for (var i = 0; i < 8; i++)
        {
            var current = (value & 0x80) != 0;
            if (_prev == current)
                _state ^= 3;
            _prev = current;
            value <<= 1;
            for (var j = 0; j < UsbClock / 12; j++)
                result[idx++] = _state;
        }
        return result;
    }
}