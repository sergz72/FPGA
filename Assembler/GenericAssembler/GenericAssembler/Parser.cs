using System.Text;

namespace GenericAssembler;

public interface IParser
{
    List<Token> Parse(string line);
}

public enum TokenType
{
    Name,
    Number,
    Symbol
}

public record Token(TokenType Type, string StringValue, int IntValue, char CharValue)
{
    public bool IsChar(char value)
    {
        return Type == TokenType.Symbol && CharValue == value;
    }
}

public sealed class ParserException(string message) : Exception(message);

public class GenericParser: IParser
{
    protected enum ParserMode
    {
        None,
        Name,
        Number,
        HexNumber
    }
    
    protected ParserMode Mode;
    protected readonly List<Token> Result;
    protected readonly StringBuilder Builder;
    protected int IntValue;
    
    public GenericParser()
    {
        Result = [];
        Builder = new StringBuilder();
    }

    protected bool ModeNameHandler(char c)
    {
        switch (c)
        {
            case ';':
                return true;
            case <= ' ':
                Mode = ParserMode.None;
                Result.Add(new Token(TokenType.Name, Builder.ToString(), 0, ' '));
                Builder.Clear();
                break;
            case >= '0' and <= '9':
            case >= 'a' and <= 'z':
            case >= 'A' and <= 'Z':
            case '.':
            case '_':
                Builder.Append(c);
                break;
            case '+':
            case '-':
            case '*':
            case '/':
            case ',':
            case ':':
            case '[':
            case ']':
                Mode = ParserMode.None;
                Result.Add(new Token(TokenType.Name, Builder.ToString(), 0, ' '));
                Builder.Clear();
                Result.Add(new Token(TokenType.Symbol, "", 0, c));
                break;
            default:
                throw new ParserException("invalid symbol in name: " + c);
        }

        return false;
    }

    protected bool ModeHexNumberHandler(char c)
    {
        switch (c)
        {
            case <= ' ':
                Mode = ParserMode.None;
                Result.Add(new Token(TokenType.Number, "", IntValue, ' '));
                break;
            case ';':
                return true;
            case >= '0' and <= '9':
                IntValue <<= 4;
                IntValue |= c - '0';
                break;
            case >= 'a' and <= 'f':
                IntValue <<= 4;
                IntValue |= c - 'a' + 10;
                break;
            case >= 'A' and <= 'F':
                IntValue <<= 4;
                IntValue |= c - 'A' + 10;
                break;
            case '+':
            case '-':
            case '*':
            case '/':
            case ',':
            case ':':
            case '[':
            case ']':
                Mode = ParserMode.None;
                Result.Add(new Token(TokenType.Number, "", IntValue, ' '));
                Result.Add(new Token(TokenType.Symbol, "", 0, c));
                break;
            default:
                throw new ParserException("invalid symbol in number: " + c);
        }
        return false;
    }

    protected bool ModeNumberHandler(char c)
    {
        switch (c)
        {
            case <= ' ':
                Mode = ParserMode.None;
                Result.Add(new Token(TokenType.Number, "", IntValue, ' '));
                break;
            case ';':
                return true;
            case >= '0' and <= '9':
                IntValue *= 10;
                IntValue += c - '0';
                break;
            case '+':
            case '-':
            case '*':
            case '/':
            case ',':
            case ':':
            case '[':
            case ']':
                Mode = ParserMode.None;
                Result.Add(new Token(TokenType.Number, "", IntValue, ' '));
                Result.Add(new Token(TokenType.Symbol, "", 0, c));
                break;
            default:
                throw new ParserException("invalid symbol in number: " + c);
        }
        return false;
    }
    
    protected bool ModeNoneHandler(char c)
    {
        switch (c)
        {
            case ';':
                return true;
            case <= ' ':
                break;
            case '$':
                Mode = ParserMode.HexNumber;
                IntValue = 0;
                break;
            case >= '0' and <= '9':
                Mode = ParserMode.Number;
                IntValue = c - '0';
                break;
            case >= 'a' and <= 'z':
            case >= 'A' and <= 'Z':
            case '.':
            case '_':
                Mode = ParserMode.Name;
                Builder.Append(c);
                break;
            case '+':
            case '-':
            case '*':
            case '/':
            case ',':
            case ':':
            case '[':
            case ']':
                Result.Add(new Token(TokenType.Symbol, "", 0, c));
                break;
            default:
                throw new ParserException("unknown symbol " + c);
        }

        return false;
    }

    protected void Finish()
    {
        switch (Mode)
        {
            case ParserMode.Name:
                Result.Add(new Token(TokenType.Name, Builder.ToString(), 0, ' '));
                Builder.Clear();
                break;
            case ParserMode.Number:
            case ParserMode.HexNumber:
                Result.Add(new Token(TokenType.Number, "", IntValue, ' '));
                break;
        }
    }
    
    public List<Token> Parse(string line)
    {
        Mode = ParserMode.None;
        Result.Clear();

        foreach (var c in line)
        {
            var exit = Mode switch
            {
                ParserMode.None => ModeNoneHandler(c),
                ParserMode.Number => ModeNumberHandler(c),
                ParserMode.HexNumber => ModeHexNumberHandler(c),
                ParserMode.Name => ModeNameHandler(c)
            };
            if (exit)
                break;
        }

        Finish();
        
        return Result;
    }
}