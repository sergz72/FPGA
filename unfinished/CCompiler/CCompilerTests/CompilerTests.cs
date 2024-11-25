using CCompiler;

namespace CCompilerTests;

public class CompilerTests
{
    [SetUp]
    public void Setup()
    {
    }

    [Test]
    public void TestPreprocessor()
    {
        const string fileName = "../../../test_files/test_defines.c";
        var fullName = Path.GetFullPath(fileName);
        const string definesFileName = "../../../test_files/defines.h";
        var definesFullName = Path.GetFullPath(definesFileName);
        var compiler = new CCompiler.CCompiler([fileName], new Preprocessor([], []));
        compiler.Compile(false);
        Assert.That(compiler.Preprocessor.Defines, Has.Count.EqualTo(5));
        Assert.That(compiler.Preprocessor.Defines.ContainsKey("B"), Is.True);
        Assert.That(compiler.Preprocessor.Defines.ContainsKey("C"), Is.True);
        Assert.That(compiler.Preprocessor.Defines.ContainsKey("D"), Is.True);
        Assert.That(compiler.Preprocessor.Defines.ContainsKey("A"), Is.True);
        Assert.That(compiler.Preprocessor.Defines.ContainsKey("E"), Is.True);
        Assert.That(new List<Token>() {new Token(TokenType.Number, "", 1, definesFullName, 1, 11)},
            Is.EqualTo(compiler.Preprocessor.Defines["B"].Tokens));
        Assert.That(new List<Token>() {new Token(TokenType.Number, "", 2, definesFullName, 2, 11)},
            Is.EqualTo(compiler.Preprocessor.Defines["C"].Tokens));
        Assert.That(new List<Token>() {new Token(TokenType.Number, "", 3, definesFullName, 3, 11)},
            Is.EqualTo(compiler.Preprocessor.Defines["D"].Tokens));
        Assert.That(new List<Token>()
        {
            new(TokenType.Number, "", 1, definesFullName, 1, 11),
            new(TokenType.Symbol, "+", 0, definesFullName, 4, 13),
            new(TokenType.Number, "", 2, definesFullName, 2, 11),
            new(TokenType.Symbol, "+", 0, definesFullName, 4, 17),
            new(TokenType.Number, "", 3, definesFullName, 3, 11),
        }, Is.EqualTo(compiler.Preprocessor.Defines["A"].Tokens));
        Assert.That(new List<Token>()
        {
            new(TokenType.Number, "", 1, definesFullName, 1, 11),
            new(TokenType.Symbol, "+", 0, definesFullName, 4, 13),
            new(TokenType.Number, "", 2, definesFullName, 2, 11),
            new(TokenType.Symbol, "+", 0, definesFullName, 4, 17),
            new(TokenType.Number, "", 3, definesFullName, 3, 11),
            new(TokenType.Symbol, "+", 0, definesFullName, 6, 12),
            new(TokenType.Number, "", 3, definesFullName, 3, 11),
        }, Is.EqualTo(compiler.Preprocessor.Defines["E"].Tokens));
    }

    [Test]
    public void TestCompiler()
    {
        const string fileName = "../../../test_files/test.c";
        var compiler = new CCompiler.CCompiler([fileName], new Preprocessor([], []));
        compiler.Compile(false);
        var code = compiler.GenerateCode();
    }
}