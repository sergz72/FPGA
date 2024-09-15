using CCompiler.ProgramBlocks;

namespace CCompiler;

internal class ResourcePlanner
{
    internal record VariableRegisters(int[] Main, int[] Temp);

    private readonly int _numberOfRegisters;
    private readonly int _registerSize;
    private readonly CCompiler _compiler;

    internal readonly Dictionary<Variable, VariableRegisters> VariableMap;
    internal readonly Dictionary<string, int[]> FunctionRegisterPushMap;
    
    internal ResourcePlanner(int numberOfRegisters, int registerSize, CCompiler compiler)
    {
        _numberOfRegisters = numberOfRegisters;
        _registerSize = registerSize;
        _compiler = compiler;
        VariableMap = new Dictionary<Variable, VariableRegisters>();
        FunctionRegisterPushMap = new Dictionary<string, int[]>();
    }

    internal void AssignResources()
    {
        var callGraph = CreateCallGraph();
        PrintCallGraph(callGraph);
        throw new NotImplementedException();
    }

    private void PrintCallGraph(Dictionary<string, HashSet<string>> callGraph)
    {
        foreach (var item in callGraph)
            Console.WriteLine($"{item.Key}:\n  {item.Value}");
    }

    private Dictionary<string, HashSet<string>> CreateCallGraph()
    {
        return _compiler.Functions.Keys.ToDictionary(f => f, CreateCallGraph);
    }

    private HashSet<string> CreateCallGraph(string functionName)
    {
        return _compiler.Functions[functionName].ProgramBlocks
            .Where(pb => pb is Call)
            .Select(pb => ((Call)pb).FunctionName)
            .ToHashSet();
    }
}