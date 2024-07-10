using System.Text;

namespace Cpu16Assembler;

internal interface IParser
{
    List<Token> Parse(string line);
}

internal enum TokenType
{
    Name,
    Number,
    Symbol
}

internal record Token(TokenType Type, string StringValue, int IntValue, char CharValue)
{
    internal bool IsChar(char value)
    {
        return Type == TokenType.Symbol && CharValue == value;
    }
}

internal sealed class ParserException(string message) : Exception(message);

internal sealed class Parser: IParser
{
    private enum Mode
    {
        None,
        Name,
        Number,
        HexNumber
    }
    
    private Mode _mode;
    private readonly List<Token> _result;
    private readonly StringBuilder _builder;
    private int _intValue;
    
    internal Parser()
    {
        _result = [];
        _builder = new StringBuilder();
    }

    private bool ModeNameHandler(char c)
    {
        switch (c)
        {
            case ';':
                return true;
            case <= ' ':
                _mode = Mode.None;
                _result.Add(new Token(TokenType.Name, _builder.ToString(), 0, ' '));
                _builder.Clear();
                break;
            case >= '0' and <= '9':
            case >= 'a' and <= 'z':
            case >= 'A' and <= 'Z':
            case '.':
            case '_':
                _builder.Append(c);
                break;
            case '+':
            case '-':
            case '*':
            case '/':
            case ',':
            case ':':
                _mode = Mode.None;
                _result.Add(new Token(TokenType.Name, _builder.ToString(), 0, ' '));
                _builder.Clear();
                _result.Add(new Token(TokenType.Symbol, "", 0, c));
                break;
            default:
                throw new ParserException("invalid symbol in name: " + c);
        }

        return false;
    }

    private bool ModeHexNumberHandler(char c)
    {
        switch (c)
        {
            case <= ' ':
                _mode = Mode.None;
                _result.Add(new Token(TokenType.Number, "", _intValue, ' '));
                break;
            case ';':
                return true;
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
            case '+':
            case '-':
            case '*':
            case '/':
            case ',':
            case ':':
                _mode = Mode.None;
                _result.Add(new Token(TokenType.Number, "", _intValue, ' '));
                _result.Add(new Token(TokenType.Symbol, "", 0, c));
                break;
            default:
                throw new ParserException("invalid symbol in number: " + c);
        }
        return false;
    }

    private bool ModeNumberHandler(char c)
    {
        switch (c)
        {
            case <= ' ':
                _mode = Mode.None;
                _result.Add(new Token(TokenType.Number, "", _intValue, ' '));
                break;
            case ';':
                return true;
            case >= '0' and <= '9':
                _intValue *= 10;
                _intValue += c - '0';
                break;
            case '+':
            case '-':
            case '*':
            case '/':
            case ',':
            case ':':
                _mode = Mode.None;
                _result.Add(new Token(TokenType.Number, "", _intValue, ' '));
                _result.Add(new Token(TokenType.Symbol, "", 0, c));
                break;
            default:
                throw new ParserException("invalid symbol in number: " + c);
        }
        return false;
    }
    
    private bool ModeNoneHandler(char c)
    {
        switch (c)
        {
            case ';':
                return true;
            case <= ' ':
                break;
            case '$':
                _mode = Mode.HexNumber;
                _intValue = 0;
                break;
            case >= '0' and <= '9':
                _mode = Mode.Number;
                _intValue = c - '0';
                break;
            case >= 'a' and <= 'z':
            case >= 'A' and <= 'Z':
            case '.':
            case '_':
                _mode = Mode.Name;
                _builder.Append(c);
                break;
            case '+':
            case '-':
            case '*':
            case '/':
            case ',':
            case ':':
                _result.Add(new Token(TokenType.Symbol, "", 0, c));
                break;
            default:
                throw new ParserException("unknown symbol " + c);
        }

        return false;
    }

    private void Finish()
    {
        switch (_mode)
        {
            case Mode.Name:
                _result.Add(new Token(TokenType.Name, _builder.ToString(), 0, ' '));
                _builder.Clear();
                break;
            case Mode.Number:
            case Mode.HexNumber:
                _result.Add(new Token(TokenType.Number, "", _intValue, ' '));
                break;
        }
    }
    
    public List<Token> Parse(string line)
    {
        _mode = Mode.None;
        _result.Clear();

        foreach (var c in line)
        {
            var exit = _mode switch
            {
                Mode.None => ModeNoneHandler(c),
                Mode.Number => ModeNumberHandler(c),
                Mode.HexNumber => ModeHexNumberHandler(c),
                Mode.Name => ModeNameHandler(c)
            };
            if (exit)
                break;
        }

        Finish();
        
        return _result;
    }
}