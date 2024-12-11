namespace UsbDecoderTests;

[TestClass]
public sealed class CRCTests
{
    [TestMethod]
    public void TestCheckCRC5()
    {
        //111_0111_1101 00110
        Assert.IsTrue(UsbDecoder.UsbDecoder.CheckCrc5(0b_01100_1011_1110_111));
    }
}