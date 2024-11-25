using CCompiler.ProgramBlocks;

namespace CCompiler;

internal class Cpu16Lite: ICpu
{
    private readonly CCompiler _compiler;
    private readonly ResourcePlanner _planner;
    
    internal Cpu16Lite(CCompiler compiler)
    {
        _compiler = compiler;

        _planner = new ResourcePlanner(
            256, // registers
            2, // register size in bytes
            _compiler
        );
    }

    public List<string> GenerateCode()
    {
        _planner.AssignResources();
        return BuildCode();
    }

    private List<string> BuildCode()
    {
        var result = new List<string>();
        result.Add("  jmp initGlobalVariables");
        GenerateFunctionCode(result, "isr", _compiler.Functions["isr"], "reti");
        result.Add("initGlobalVariables:");
        GenerateInitVariablesCode(result, _compiler.Variables);
        GenerateFunctionCode(result, "main", _compiler.Functions["main"]);
        foreach (var f in _compiler.Functions)
        {
            if (f.Key != "isr" && f.Key != "main")
                GenerateFunctionCode(result, f.Key, f.Value);
        }
        return result;
    }

    private void GenerateInitVariablesCode(List<string> result, Dictionary<string, Variable> variables)
    {
        foreach (var variable in variables)
            GenerateInitVariableCode(result, variable.Value);
    }

    private void GenerateInitVariableCode(List<string> result, Variable variable)
    {
        if (variable.Value != null)
        {
            var registers = _planner.VariableMap[variable];
            throw new NotImplementedException();
            //result.Add($"  mov {r}, {value}");
        }
    }

    private void GenerateFunctionCode(List<string> result, string name, Function function, string returnStatement = "ret")
    {
        GenerateInitVariablesCode(result, function.Variables);
        result.Add(name + ":");
        foreach (var block in function.ProgramBlocks)
            GenerateProgramBlockCode(result, block);
        result.Add("  " + returnStatement);
    }
    
    private void GenerateProgramBlockCode(List<string> result, IProgramBlock block)
    {
        if (block is Expression expression)
            GenerateExpressionCode(result, expression);
        else
            throw new NotImplementedException();
    }

    private void GenerateExpressionCode(List<string> result, Expression expression)
    {
        /*var vr = _planner.VariableMap[expression.Variable];
        var registers = vr.Main;
        if (expression.DerefsCount != 0)
            registers = vr.Temp;
        GenerateExpressionValueCode(result, registers, expression.Value, expression.Op);
        if (expression.DerefsCount != 0)
            result.Add($"  out [{vr}], {registers}");*/
    }

    private void GenerateExpressionValueCode(List<string> result, int[] registers,
                                                List<ExpressionParser.OutputItem> expressionValue, string op)
    {
        var operands = new ExpressionParser.OutputItem?[2];
        var operandIdx = 0;
        
        foreach (var item in expressionValue)
        {
            if (item.Op != null)
            {
                GenerateExpressionItemCode(result, registers, item.Op, operands[0], operands[1]);
                operandIdx = 0;
                operands[0] = operands[1] = null;
            }
            else
                operands[operandIdx++] = item;
        }
        var value = operands[0]?.Value == null ? _planner.VariableMap[operands[0]!.Var!].ToString() : operands[0]?.Value.ToString();
        switch (op)
        {
            case "-=":
                result.Add($"  sub {registers}, {value}");
                break;
            case "+=":
                result.Add($"  add {registers}, {value}");
                break;
            case "=":
                result.Add($"  mov {registers}, {value}");
                break;
            default:
                throw new CPUException($"Unknown operator {op}");
        }
    }

    private void GenerateExpressionItemCode(List<string> result, int[] registers, string op,
                                            ExpressionParser.OutputItem? op1, ExpressionParser.OutputItem? op2)
    {
        throw new NotImplementedException();
    }
}