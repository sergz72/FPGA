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
    Symbol,
    String
}

public record Token(TokenType Type, string StringValue, int IntValue)
{
    public Token(char charValue) : this(TokenType.Symbol, charValue.ToString(), 0)
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
}

public sealed class ParserException(string message) : Exception(message);

public class GenericParser: IParser
{
    protected enum ParserMode
    {
        None,
        Name,
        Number,
        HexNumber,
        Symbol,
        Char1,
        Char2,
        String
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
            case >= '0' and <= '9':
            case >= 'a' and <= 'z':
            case >= 'A' and <= 'Z':
            case '.':
            case '_':
                Builder.Append(c);
                break;
            default:
                Mode = ParserMode.None;
                Result.Add(new Token(TokenType.Name, Builder.ToString(), 0));
                Builder.Clear();
                return ModeNoneHandler(c);
        }

        return false;
    }

    protected bool ModeHexNumberHandler(char c)
    {
        switch (c)
        {
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
            default:
                Mode = ParserMode.None;
                Result.Add(new Token(TokenType.Number, "", IntValue));
                return ModeNoneHandler(c);
        }
        return false;
    }

    protected bool ModeNumberHandler(char c)
    {
        switch (c)
        {
            case >= '0' and <= '9':
                IntValue *= 10;
                IntValue += c - '0';
                break;
            default:
                Mode = ParserMode.None;
                Result.Add(new Token(TokenType.Number, "", IntValue));
                return ModeNoneHandler(c);
        }
        return false;
    }

    protected bool ModeSymbolHandler(char c)
    {
        switch (c)
        {
            case '=':
                if (c == Builder[0] || Builder[0] == '<' || Builder[0] == '>' || Builder[0] == '!')
                {
                    Builder.Append(c);
                    Result.Add(new Token(TokenType.Symbol, Builder.ToString(), 0));
                }
                else
                {
                    Result.Add(new Token(TokenType.Symbol, Builder.ToString(), 0));
                    Result.Add(new Token(c));
                }
                Mode = ParserMode.None;
                Builder.Clear();
                break;
            case '+':
            case '-':
            case '<':
            case '>':
            case '|':
            case '&':
                if (c == Builder[0])
                {
                    Builder.Append(c);
                    Result.Add(new Token(TokenType.Symbol, Builder.ToString(), 0));
                }
                else
                {
                    Result.Add(new Token(TokenType.Symbol, Builder.ToString(), 0));
                    Result.Add(new Token(c));
                }
                Mode = ParserMode.None;
                Builder.Clear();
                break;
            default:
                Mode = ParserMode.None;
                Result.Add(new Token(TokenType.Symbol, Builder.ToString(), 0));
                Builder.Clear();
                return ModeNoneHandler(c);
        }

        return false;
    }

    protected bool ModeChar1Handler(char c)
    {
        IntValue = c;
        Mode = ParserMode.Char2;
        return false;
    }

    protected bool ModeChar2Handler(char c)
    {
        if (c != '\'')
            throw new ParserException("' expected");
        Result.Add(new Token(TokenType.Number, "", IntValue));
        Mode = ParserMode.None;
        return false;
    }

    protected bool ModeStringHandler(char c)
    {
        if (c != '"')
            Builder.Append(c);
        else
        {
            Result.Add(new Token(TokenType.String, Builder.ToString(), 0));
            Builder.Clear();
            Mode = ParserMode.None;
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
            case '<':
            case '>':
            case '|':
            case '&':
            case '=':
            case '!':
                Mode = ParserMode.Symbol;
                Builder.Append(c);
                break;
            case '*':
            case '/':
            case ',':
            case ':':
            case '[':
            case ']':
            case '(':
            case ')':
            case '^':
            case '@':
                Result.Add(new Token(c));
                break;
            case '\'':
                Mode = ParserMode.Char1;
                break;
            case '"':
                Mode = ParserMode.String;
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
                Result.Add(new Token(TokenType.Name, Builder.ToString(), 0));
                Builder.Clear();
                break;
            case ParserMode.Number:
            case ParserMode.HexNumber:
                Result.Add(new Token(TokenType.Number, "", IntValue));
                break;
            case ParserMode.Symbol:
                Result.Add(new Token(TokenType.Symbol, Builder.ToString(), 0));
                Builder.Clear();
                break;
            case ParserMode.None:
                break;
            default:
                throw new ParserException("unexpected end of file");
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
                ParserMode.Name => ModeNameHandler(c),
                ParserMode.Symbol => ModeSymbolHandler(c),
                ParserMode.Char1 => ModeChar1Handler(c),
                ParserMode.Char2 => ModeChar2Handler(c),
                ParserMode.String => ModeStringHandler(c)
            };
            if (exit)
                break;
        }

        Finish();
        
        return Result;
    }
}