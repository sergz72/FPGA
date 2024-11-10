namespace GenericAssembler;

public sealed class Linker: ICompiler
{
    private record Section(uint StartAddress, uint Size, string FileName, string[] Contains);
    
    private readonly Dictionary<string, Section> _sections;
    private readonly ExpressionParser _eParser;
    private readonly string _currentFileName;
    private readonly Dictionary<string, int> _constants = [];
    private readonly IParser _parser;
    private int _currentLineNo;
    
    internal Linker(string? fileName)
    {
        _currentFileName = fileName ?? "";
        _eParser = new ExpressionParser(256, this);
        _parser = new GenericParser();
        _sections = fileName != null ? BuildSections(fileName) : BuildDefaultSections();
    }

    private static Dictionary<string, Section> BuildDefaultSections()
    {
        return new Dictionary<string, Section>
        {
            {"code", new Section(0, 32768, "code", ["code"])},
            {"data", new Section(0x8000, 32768, "data", ["data", "bss"])}
        };
    }

    private Dictionary<string, Section> BuildSections(string fileName)
    {
        var lines = File.ReadAllLines(fileName);
        _currentLineNo = 0;
        var sections = new Dictionary<string, Section>();
        foreach (var line in lines)
        {
            _currentLineNo++;
            var tokens = _parser.Parse(line);
            if (tokens.Count == 0)
                continue;
            Parse(sections, tokens);
        }
        return sections;
    }

    private void Parse(Dictionary<string, Section> sections, List<Token> tokens)
    {
        if (tokens.Count < 3)
            throw new GenericCompiler.CompilerException(_currentFileName, _currentLineNo, "at least 3 tokens expected");
        if (tokens[0].Type != TokenType.Name)
            throw new GenericCompiler.CompilerException(_currentFileName, _currentLineNo, "name expected");
        if (tokens[0].StringValue == "section")
            ParseSectionDefinition(sections, tokens[1..]);
        else
            ParseConstantDefinition(tokens[0].StringValue, tokens[1..]);
    }

    private void ParseConstantDefinition(string name, List<Token> tokens)
    {
        if (!tokens[0].IsChar('='))
            throw new GenericCompiler.CompilerException(_currentFileName, _currentLineNo, "= expected");
        var start = 1;
        var value = CalculateExpression(tokens, ref start);
        AddConstant(name, value);
    }

    private void ParseSectionDefinition(Dictionary<string, Section> segments, List<Token> tokens)
    {
        if (tokens[0].Type != TokenType.Name)
            throw new GenericCompiler.CompilerException(_currentFileName, _currentLineNo, "segment name expected");
        var segmentName = tokens[0].StringValue;
        if (segments.ContainsKey(segmentName))
            throw new GenericCompiler.CompilerException(_currentFileName, _currentLineNo,
                                                        $"segment {segmentName} already defined");
        var start = 1;
        var parameters = new Dictionary<string, (string, uint)>();
        while (start < tokens.Count)
        {
            if (start > tokens.Count - 2 || tokens[start].Type != TokenType.Name || !tokens[start + 1].IsChar('='))
                throw new GenericCompiler.CompilerException(_currentFileName, _currentLineNo,
                    "parameter=value expected");
            var parameter = tokens[start].StringValue;
            if (parameters.ContainsKey(parameter))
                throw new GenericCompiler.CompilerException(_currentFileName, _currentLineNo,
                    $"parameter {parameter} already defined");
            if (parameter != "size" && parameter != "address" && parameter != "file" && parameter != "contains")
                throw new GenericCompiler.CompilerException(_currentFileName, _currentLineNo,
                    $"invalid parameter name: {parameter}");
            start += 2;
            if (parameter is "size" or "address")
            {
                var value = CalculateExpression(tokens, ref start);
                if (value < 0)
                    throw new GenericCompiler.CompilerException(_currentFileName, _currentLineNo, "negative parameter value");
                parameters[parameter] = ("", (uint)value);
            }
            else
            {
                if (tokens[start].Type != TokenType.String)
                    throw new GenericCompiler.CompilerException(_currentFileName, _currentLineNo, "string expected");
                parameters[parameter] = (tokens[start++].StringValue, 0);
            }
            if (start < tokens.Count && !tokens[start++].IsChar(','))
                throw new GenericCompiler.CompilerException(_currentFileName, _currentLineNo, ", expected");
        }

        if (!parameters.TryGetValue("size", out var size))
            throw new GenericCompiler.CompilerException(_currentFileName, _currentLineNo, "size is not defined");
        if (!parameters.TryGetValue("address", out var address))
            throw new GenericCompiler.CompilerException(_currentFileName, _currentLineNo, "address is not defined");
        if (!parameters.TryGetValue("file", out var file))
            throw new GenericCompiler.CompilerException(_currentFileName, _currentLineNo, "file is not defined");
        
        if (!parameters.TryGetValue("contains", out var contains))
            contains = (segmentName, 0);
        segments.Add(segmentName,
                     new Section(address.Item2, size.Item2, file.Item1, contains.Item1.Split(',').ToArray()));
    }

    internal (string, uint) GetSectionNameAndAddress(string segmentName)
    {
        var section = _sections
            .FirstOrDefault(s => s.Value.Contains.Contains(segmentName));
        if (section.Key == "")
            throw new GenericCompiler.CompilerException(_currentFileName, _currentLineNo, $"undeclared segment {segmentName}");
        return (section.Key, section.Value.StartAddress);
    }

    internal string GetFileName(string sectionName, OutputFormat outputFileFormat)
    {
        return _sections[sectionName].FileName + (outputFileFormat == OutputFormat.Hex ? ".hex" : ".bin");
    }
    
    public int CalculateExpression(List<Token> tokens, ref int start)
    {
        return _eParser.Parse(tokens, ref start);
    }

    public string FindRegisterNumber(string registerName)
    {
        throw new NotImplementedException();
    }

    public void AddConstant(string name, int value)
    {
        if (!_constants.TryAdd(name, value))
            throw new GenericCompiler.CompilerException(_currentFileName, _currentLineNo,
                                                        $"constant with name {name} already defined");
    }

    public int FindConstantValue(string name)
    {
        if (!_constants.TryGetValue(name, out var result))
            throw new GenericCompiler.CompilerException(_currentFileName, _currentLineNo,
                                                        $"undefined constant name: {name}");
        return result;
    }

    public uint? FindLabel(string name)
    {
        throw new NotImplementedException();
    }

    public void RaiseException(string errorMessage) =>
        throw new GenericCompiler.CompilerException(_currentFileName, _currentLineNo, errorMessage);

    public Token GetNextToken(List<Token> tokens, ref int start)
    {
        if (start == tokens.Count)
            throw new GenericCompiler.CompilerException(_currentFileName, _currentLineNo, "unexpected end of line");
        return tokens[start++];
    }
}