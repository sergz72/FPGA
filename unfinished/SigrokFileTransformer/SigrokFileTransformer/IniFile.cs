namespace SigrokFileTransformer;

public class IniFile
{
    public readonly Dictionary<string, Dictionary<string, string>> Sections;
    
    public IniFile(string[] lines)
    {
        Sections = new Dictionary<string, Dictionary<string, string>>();
        Dictionary<string, string>? currentSection = null;
        
        foreach (var line in lines)
        {
            var trimmed = line.Trim();
            if (trimmed.Length == 0)
                continue;
            if (trimmed.StartsWith('[') && trimmed.EndsWith(']'))
            {
                var sectionName = trimmed[1..^1].Trim();
                if (sectionName.Length > 0)
                {
                    currentSection = new Dictionary<string, string>();
                    Sections.Add(sectionName, currentSection);
                }
            }
            else if (currentSection != null)
            {
                var parts = trimmed.Split('=', 2);
                if (parts.Length == 2)
                    currentSection.Add(parts[0].Trim(), parts[1].Trim());
            }
        }
    }
}