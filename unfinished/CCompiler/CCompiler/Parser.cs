using System.Text;

namespace CCompiler;

public enum TokenType
{
    Name,
    Number,
    Symbol,
    String,
    Keyword,
    Eol
}

public record Token(TokenType Type, string StringValue, int IntValue, string FileName, int Line, int StartChar)
{
    public Token(char charValue, string fileName, int line, int startChar) :
        this(TokenType.Symbol, charValue.ToString(), 0, fileName, line, startChar)
    {
        
    }

    public Token(string fileName, int line, int startChar) :
        this(TokenType.Eol, "", 0, fileName, line, startChar)
    {
        
    }
    
    public bool IsChar(string value)
    {
        return Type == TokenType.Symbol && StringValue == value;
    }

    public bool IsChar(char value)
    {
        return Type == TokenType.Symbol && StringValue.Length == 1 && StringValue[0] == value;
    }

    public bool IsAnyOfKeywords(params CParser.Keyword[] keywords)
    {
        return Type == TokenType.Keyword && keywords.Contains((CParser.Keyword)IntValue);
    }

    public bool IsDataTypeKeyword()
    {
        return Type == TokenType.Keyword && CParser.DataTypeKeywords.Contains((CParser.Keyword)IntValue);
    }
    
    public override string ToString()
    {
        return $"{Type} StringValue: {StringValue} IntValue: {IntValue}";
    }

    public void Print()
    {
        switch (Type)
        {
            case TokenType.Number:
                Console.Write($"{IntValue} ");
                break;
            case TokenType.String:
                Console.Write($"\"{StringValue}\" ");
                break;
            default:
                Console.Write($"{StringValue} ");
                break;
        }
    }
}

internal sealed class ParserException(string message) : Exception(message);

public sealed class CParser
{
    public enum Keyword
    {
        Auto = 0,
        Else,
        Long,
        Switch,
        Break,
        Enum,
        Register,
        Typedef,
        Case,
        Extern,
        Return,
        Union,
        Char,
        Float,
        Short,
        Unsigned,
        Const,
        For,
        Signed,
        Void,
        Continue,
        Goto,
        Sizeof,
        Volatile,
        Default,
        If,
        Static,
        While,
        Do,
        Int,
        Struct,
        Double
    }

    public static readonly Keyword[] DataTypeKeywords =
    [
        Keyword.Long,
        Keyword.Enum,
        Keyword.Register,
        Keyword.Extern,
        Keyword.Union,
        Keyword.Char,
        Keyword.Float,
        Keyword.Short,
        Keyword.Unsigned,
        Keyword.Const,
        Keyword.Signed,
        Keyword.Void,
        Keyword.Volatile,
        Keyword.Static,
        Keyword.Int,
        Keyword.Struct,
        Keyword.Double
    ];
    
    private static readonly string[] Keywords = [
        "auto","else","long","switch",
        "break","enum","register","typedef",
        "case","extern","return","union",
        "char","float","short","unsigned",
        "const","for","signed","void",
        "continue","goto","sizeof","volatile",
        "default","if","static","while",
        "do","int","struct", "double"
    ];
    
    private enum ParserMode
    {
        None,
        Name,
        Number,
        HexNumber,
        OctNumber,
        Symbol,
        Char1,
        Char2,
        String,
        Slash,
        Comment,
        Comment2,
        LineComment,
        Zero
    }

    private readonly List<Token> _result;
    private readonly StringBuilder _builder;
    private readonly string _code;

    private int _intValue;
    private ParserMode _mode;
    private int _line;
    private int _startChar;
    private int _currentChar;
    private readonly string _fileName;
    
    public CParser(string filename, string code)
    {
        _result = [];
        _builder = new StringBuilder();
        _code = code;
        _mode = ParserMode.None;
        _line = 1;
        _currentChar = 1;
        _fileName = filename;
    }

    private void FinishName()
    {
        var name = _builder.ToString();
        var index = Array.FindIndex(Keywords, kv => kv == name);
        if (index >= 0)
            _result.Add(new Token(TokenType.Keyword, "", index, _fileName, _line, _startChar));
        else                    
            _result.Add(new Token(TokenType.Name, name, 0, _fileName, _line, _startChar));
    }
    
    private void ModeNameHandler(char c)
    {
        switch (c)
        {
            case >= '0' and <= '9':
            case >= 'a' and <= 'z':
            case >= 'A' and <= 'Z':
            case '_':
                _builder.Append(c);
                break;
            default:
                _mode = ParserMode.None;
                FinishName();
                _builder.Clear();
                ModeNoneHandler(c);
                break;
        }
    }

    private void ModeHexNumberHandler(char c)
    {
        switch (c)
        {
            case >= '0' and <= '9':
                _intValue <<= 4;
                _intValue |= c - '0';
                break;
            case >= 'a' and <= 'f':
                _intValue <<= 4;
                _intValue |= c - 'a' + 10;
                break;
            case >= 'A' and <= 'F':
                _intValue <<= 4;
                _intValue |= c - 'A' + 10;
                break;
            default:
                _mode = ParserMode.None;
                _result.Add(new Token(TokenType.Number, "", _intValue, _fileName, _line, _startChar));
                ModeNoneHandler(c);
                break;
        }
    }

    private void ModeNumberHandler(char c)
    {
        switch (c)
        {
            case >= '0' and <= '9':
                _intValue *= 10;
                _intValue += c - '0';
                break;
            default:
                _mode = ParserMode.None;
                _result.Add(new Token(TokenType.Number, "", _intValue, _fileName, _line, _startChar));
                ModeNoneHandler(c);
                break;
        }
    }

    private void ModeOctNumberHandler(char c)
    {
        switch (c)
        {
            case >= '0' and <= '7':
                _intValue <<= 3;
                _intValue += c - '0';
                break;
            default:
                _mode = ParserMode.None;
                _result.Add(new Token(TokenType.Number, "", _intValue, _fileName, _line, _startChar));
                ModeNoneHandler(c);
                break;
        }
    }
    
    private void ModeSymbolHandler(char c)
    {
        switch (c)
        {
            case '.':
                if (c != _builder[^1])
                {
                    _result.Add(new Token(TokenType.Symbol, _builder.ToString(), 0, _fileName, _line, _startChar));
                    _result.Add(new Token(c, _fileName, _line, _startChar));
                    _mode = ParserMode.None;
                    _builder.Clear();
                }
                _builder.Append(c);
                break;
            case '=':
                if (c == _builder[0] || _builder[0] == '<' || _builder[0] == '>' || _builder[0] == '!' ||
                    _builder[0] == '+' || _builder[0] == '-' || _builder[0] == '*' || _builder[0] == '/' ||
                    _builder[0] == '|' || _builder[0] == '&' || _builder[0] == '^' || _builder[0] == '%')
                {
                    _builder.Append(c);
                    _result.Add(new Token(TokenType.Symbol, _builder.ToString(), 0, _fileName, _line, _startChar));
                }
                else
                {
                    _result.Add(new Token(TokenType.Symbol, _builder.ToString(), 0, _fileName, _line, _startChar));
                    _result.Add(new Token(c, _fileName, _line, _startChar));
                }
                _mode = ParserMode.None;
                _builder.Clear();
                break;
            case '+':
            case '-':
            case '<':
            case '>':
            case '|':
            case '&':
                if (c == _builder[0])
                {
                    _builder.Append(c);
                    _result.Add(new Token(TokenType.Symbol, _builder.ToString(), 0, _fileName, _line, _startChar));
                }
                else
                {
                    _result.Add(new Token(TokenType.Symbol, _builder.ToString(), 0, _fileName, _line, _startChar));
                    _result.Add(new Token(c, _fileName, _line, _startChar));
                }
                _mode = ParserMode.None;
                _builder.Clear();
                break;
            default:
                _mode = ParserMode.None;
                _result.Add(new Token(TokenType.Symbol, _builder.ToString(), 0, _fileName, _line, _startChar));
                _builder.Clear();
                ModeNoneHandler(c);
                break;
        }
    }

    private void ModeChar1Handler(char c)
    {
        _intValue = c;
        _mode = ParserMode.Char2;
    }

    private void ModeChar2Handler(char c)
    {
        if (c != '\'')
            throw new ParserException("' expected");
        _result.Add(new Token(TokenType.Number, "", _intValue, _fileName, _line, _startChar));
        _mode = ParserMode.None;
    }

    private void ModeStringHandler(char c)
    {
        if (c != '"')
            _builder.Append(c);
        else
        {
            _result.Add(new Token(TokenType.String, _builder.ToString(), 0, _fileName, _line, _startChar));
            _builder.Clear();
            _mode = ParserMode.None;
        }
    }
    
    private void ModeSlashHandler(char c)
    {
        switch (c)
        {
            case '/':
                _mode = ParserMode.LineComment;
                break;
            case '*':
                _mode = ParserMode.Comment;
                break;
            default:
                _result.Add(new Token('/', _fileName, _line, _startChar));
                ModeNoneHandler(c);
                break;
        }
    }

    private void ModeCommentHandler(char c)
    {
        if (c == '*')
            _mode = ParserMode.Comment2;
    }

    private void ModeComment2Handler(char c)
    {
        _mode = c == '/' ? ParserMode.None : ParserMode.Comment;
    }
    
    private void ModeLineCommentHandler(char c)
    {
        if (c == '\n')
            _mode = ParserMode.None;
    }

    private void ModeZeroHandler(char c)
    {
        if (c == 'x')
            _mode = ParserMode.HexNumber;
        else
        {
            _mode = ParserMode.OctNumber;
            ModeOctNumberHandler(c);
        }
    }
    
    private void ModeNoneHandler(char c)
    {
        switch (c)
        {
            case '/':
                _mode = ParserMode.Slash;
                _startChar = _currentChar;
                break;
            case <= ' ':
                if (c == '\n')
                    _result.Add(new Token(_fileName, _line, _currentChar));
                break;
            case '0':
                _mode = ParserMode.Zero;
                _startChar = _currentChar;
                _intValue = 0;
                break;
            case >= '1' and <= '9':
                _mode = ParserMode.Number;
                _startChar = _currentChar;
                _intValue = c - '0';
                break;
            case >= 'a' and <= 'z':
            case >= 'A' and <= 'Z':
            case '_':
            case '#':
                _mode = ParserMode.Name;
                _startChar = _currentChar;
                _builder.Append(c);
                break;
            case '+':
            case '-':
            case '<':
            case '>':
            case '|':
            case '&':
            case '=':
            case '!':
            case '.':
            case '%':
            case '*':
                _mode = ParserMode.Symbol;
                _startChar = _currentChar;
                _builder.Append(c);
                break;
            case ',':
            case ':':
            case '[':
            case ']':
            case '(':
            case ')':
            case '^':
            case '@':
            case '~':
            case ';':
            case '\\':
            case '{':
            case '}':
                _result.Add(new Token(c, _fileName, _line, _currentChar));
                break;
            case '\'':
                _mode = ParserMode.Char1;
                _startChar = _currentChar;
                break;
            case '"':
                _mode = ParserMode.String;
                _startChar = _currentChar;
                break;
            default:
                throw new ParserException("unknown symbol " + c);
        }
    }

    private void Finish()
    {
        switch (_mode)
        {
            case ParserMode.Name:
                FinishName();
                _builder.Clear();
                break;
            case ParserMode.Number:
            case ParserMode.HexNumber:
                _result.Add(new Token(TokenType.Number, "", _intValue, _fileName, _line, _startChar));
                break;
            case ParserMode.Symbol:
                _result.Add(new Token(TokenType.Symbol, _builder.ToString(), 0, _fileName, _line, _startChar));
                break;
            case ParserMode.None:
            case ParserMode.LineComment:
                break;
            default:
                throw new ParserException("unexpected end of file");
        }
    }
    
    public List<Token> Parse()
    {
        foreach (var c in _code)
        {
            switch (_mode)
            {
                case ParserMode.None:
                    ModeNoneHandler(c);
                    break;
                case ParserMode.Number:
                    ModeNumberHandler(c);
                    break;
                case ParserMode.HexNumber:
                    ModeHexNumberHandler(c);
                    break;
                case ParserMode.Name:
                    ModeNameHandler(c);
                    break;
                case ParserMode.Symbol:
                    ModeSymbolHandler(c);
                    break;
                case ParserMode.Char1:
                    ModeChar1Handler(c);
                    break;
                case ParserMode.Char2:
                    ModeChar2Handler(c);
                    break;
                case ParserMode.String:
                    ModeStringHandler(c);
                    break;
                case ParserMode.Slash:
                    ModeSlashHandler(c);
                    break;
                case ParserMode.Comment:
                    ModeCommentHandler(c);
                    break;
                case ParserMode.Comment2:
                    ModeComment2Handler(c);
                    break;
                case ParserMode.LineComment:
                    ModeLineCommentHandler(c);
                    break;
                case ParserMode.Zero:
                    ModeZeroHandler(c);
                    break;
                case ParserMode.OctNumber:
                    ModeOctNumberHandler(c);
                    break;
            }

            if (c == '\n')
            {
                _line++;
                _currentChar = 1;
            }
            else
                _currentChar++;
        }

        Finish();
        
        return _result;
    }
}