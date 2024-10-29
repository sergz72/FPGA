using System.Globalization;
using System.Text;

namespace SZForth;

public sealed class ForthParser(IEnumerable<ParserFile> sources)
{
    private enum ParserMode
    {
        Word,
        Comment,
        String
    }
    
    private NumberStyles _numberStyles;
    private string _currentFile = "";
    private int _currentLine;
    private int _currentPosition;
    private ParserMode _mode;
    private string _stringTokenWord = "";
    
    public List<Token> Parse()
    {
        var result = new List<Token>();
        foreach (var source in sources)
        {
            _numberStyles = NumberStyles.Integer;
            result.AddRange(Parse(source));
        }
        return result;
    }

    public List<Token> Parse(ParserFile source)
    {
        _currentFile = source.Filename;
        var result = new List<Token>();
        _currentLine = 1;
        _mode = ParserMode.Word;
        foreach (var line in source.Lines)
        {
            result.AddRange(ParseLine(line));
            _currentLine++;
        }
        if (_mode != ParserMode.Word)
            throw CreateException("unexpected end of file");
        return result;
    }

    public List<Token> ParseLine(string line)
    {
        var result = new List<Token>();
        _currentPosition = 1;
        var sb = new StringBuilder();
        foreach (var c in line)
        {
            if (_mode == ParserMode.String)
            {
                if (c != '"')
                    sb.Append(c);
                else
                {
                    result.Add(new Token(TokenType.Word, _stringTokenWord, null, sb.ToString(),
                        _currentFile, _currentLine, _currentPosition));
                    _mode = ParserMode.Word;
                    sb.Clear();
                }
                continue;
            }
            
            if (char.IsWhiteSpace(c))
            {
                if (sb.Length > 0)
                {
                    var (t, exit) = ParseWord(sb.ToString());
                    if (exit)
                        return result;
                    if (t != null) result.Add(t);
                    sb.Clear();
                }
            }
            else
                sb.Append(c);
            _currentPosition++;
        }
        if (sb.Length > 0)
        {
            var (t, _) = ParseWord(sb.ToString());
            if (t != null) result.Add(t);
        }
        if (_mode != ParserMode.Word && _mode != ParserMode.Comment)
            throw CreateException("unexpected end of line");
        return result;
    }
    
    private (Token?, bool) ParseWord(string word)
    {
        return _mode switch
        {
            ParserMode.Word => ParseWordMode(word),
            ParserMode.Comment => ParseCommentMode(word),
            _ => throw CreateException("Unsupported parser mode")
        };
    }
    
    private (Token?, bool) ParseCommentMode(string word)
    {
        if (word == ")")
            _mode = ParserMode.Word;
        return (null, false);
    }

    private (Token?, bool) ParseWordMode(string word)
    {
        switch (word)
        {
            case "\\":
                return (null, true);
            case "(":
                _mode = ParserMode.Comment;
                return (null, false);
            case "hex":
                _numberStyles = NumberStyles.HexNumber;
                return (null, false);
            case "decimal":
                _numberStyles = NumberStyles.Integer;
                return (null, false);
            default:
                return (BuildToken(word), false);
        }
    }

    private Token? BuildToken(string word)
    {
        if (word.Contains('"'))
        {
            _mode = ParserMode.String;
            _stringTokenWord = word;
            return null;
        }

        if (word.StartsWith('\''))
           return new Token(TokenType.Number, word, BuildChar(word), null, 
                            _currentFile, _currentLine, _currentPosition);
        
        if (int.TryParse(word, _numberStyles, NumberFormatInfo.InvariantInfo, out var value))
            return new Token(TokenType.Number, word, value, null, _currentFile, _currentLine, _currentPosition);
        return new Token(TokenType.Word, word, 0, null, _currentFile, _currentLine, _currentPosition);
    }

    private int BuildChar(string s)
    {
        if (s.Length < 3 || s.Length > 4 || !s.EndsWith('\'') || (s.Length == 4 && s[1] != '\\'))
            throw CreateException("invalid character");
        var c = s[1..^1];
        if (c.Length == 1)
            return c[0];
        switch (c[1])
        {
            case 'r': return '\r';
            case 'n': return '\n';
            case 't': return '\t';
            case 'b': return '\b';
            default: throw CreateException("invalid escape sequence");
        }
    }
    
    private ParserException CreateException(string message) => new(message, _currentFile, _currentLine, _currentPosition);
}

public record ParserFile(string Filename, string[] Lines)
{
    internal ParserFile(string fileName) : this(fileName, File.ReadAllLines(fileName))
    {
    }
}

internal class ParserException(string message, string fileName, int line, int position)
    : Exception($"{message}: {fileName}:{line}:{position}");

public enum TokenType
{
    Number,
    Word
}

public record Token(TokenType Type, string Word, int? IntValue, string? StringValue, string FileName, int Line, int Position);