using GenericAssembler;

namespace GenericAssemblerTests;

public class ExpressionParserTests
{
    [SetUp]
    public void Setup()
    {
    }

    [Test]
    public void ExpressionParserTest()
    {
        var compiler = new GenericCompiler();
        compiler.Compile("testFileName", [
            ".equ TEST1 4>>2",
            ".equ TEST2 (TEST1+3)*3/4",
            ".equ TEST3 TEST2 > TEST1",
            ".equ TEST4 TEST2 && TEST1"
        ]);
        Assert.That(compiler.FindConstantValue("TEST1"), Is.EqualTo(1));
        Assert.That(compiler.FindConstantValue("TEST2"), Is.EqualTo(3));
        Assert.That(compiler.FindConstantValue("TEST3"), Is.EqualTo(1));
        Assert.That(compiler.FindConstantValue("TEST4"), Is.EqualTo(1));
    }
}