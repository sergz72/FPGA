using SZForth;

namespace SZForthTests;

public class ParserTests
{
    [SetUp]
    public void Setup()
    {
    }

    [Test]
    public void ParserTest()
    {
        var parser = new ForthParser([new ParserFile("file.f", [
            "1234 abcde hex abcde \" text, text2\" ."
        ])]);
        var tokens = parser.Parse();
        Assert.That(tokens, Has.Count.EqualTo(5));

        Assert.That(tokens[0].Type, Is.EqualTo(TokenType.Number));
        Assert.That(tokens[0].IntValue, Is.Not.Null);
        Assert.That(tokens[0].IntValue, Is.EqualTo(1234));
        
        Assert.That(tokens[1].Type, Is.EqualTo(TokenType.Word));
        Assert.That(tokens[1].Word, Is.EqualTo("abcde"));
        
        Assert.That(tokens[2].Type, Is.EqualTo(TokenType.Number));
        Assert.That(tokens[2].IntValue, Is.Not.Null);
        Assert.That(tokens[2].IntValue, Is.EqualTo(0xabcde));
        
        Assert.That(tokens[3].Type, Is.EqualTo(TokenType.String));
        Assert.That(tokens[3].Word, Is.EqualTo(" text, text2"));
        
        Assert.That(tokens[4].Type, Is.EqualTo(TokenType.Word));
        Assert.That(tokens[4].Word, Is.EqualTo("."));
    }
}