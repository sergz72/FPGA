namespace PCapNGFileTransformer;

internal class HeaderBlock: IBlock
{
    public uint Type => 0x0a0d0d0a;

    public readonly uint ByteOrderMagic;
    public readonly ushort MajorVersion;
    public readonly ushort MinorVersion;
    public readonly ulong SectionLength;

    internal HeaderBlock()
    {
    }
    
    public IBlock Create(BinaryReader reader, uint blockLength)
    {
        return new HeaderBlock(reader);
    }

    private HeaderBlock(BinaryReader reader)
    {
        ByteOrderMagic = reader.ReadUInt32();
        MajorVersion = reader.ReadUInt16();
        MinorVersion = reader.ReadUInt16();
        SectionLength = reader.ReadUInt64();
    }

    public override string ToString()
    {
        return $"Header block byteOrder={ByteOrderMagic:X} version={MajorVersion}.{MinorVersion} sectionLength={SectionLength}";
    }
}