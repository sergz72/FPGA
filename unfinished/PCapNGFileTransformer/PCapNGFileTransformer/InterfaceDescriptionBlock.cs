namespace PCapNGFileTransformer;

internal class InterfaceDescriptionBlock: IBlock
{
    public uint Type => 1;

    public readonly ushort LinkType;
    public readonly ushort SnapLength;

    internal InterfaceDescriptionBlock()
    {
        
    }
    
    public IBlock Create(BinaryReader reader, uint blockLength)
    {
        return new InterfaceDescriptionBlock(reader);
    }
    
    private InterfaceDescriptionBlock(BinaryReader reader)
    {
        LinkType = reader.ReadUInt16();
        reader.ReadUInt16();
        SnapLength = reader.ReadUInt16();
    }

    public override string ToString()
    {
        return $"Interface description block linkType={LinkType} snapLength={SnapLength}";
    }
}