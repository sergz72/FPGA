using GenericAssembler;
using Tiny16Assembler.V6Instructions;

namespace Tiny16Assembler;

internal record ConstantValue(uint? Immediate, string? Label);
internal record ImmediateInstructionInformation(
    LoadImmediateInstruction Instruction, ConstantValue Value);
internal record ImmediateInstructions(List<LoadImmediateInstruction> Instructions, ConstantValue Value);

internal sealed class Tiny16V6Compiler : GenericCompiler
{
    private readonly List<ImmediateInstructionInformation> _loadConstantInstructionList = [];
    private List<ImmediateInstructions> _loadConstantInstructions = [];
    
    internal Tiny16V6Compiler(List<string> sources, OutputFormat outputFormat) :
        base(sources, outputFormat, Creators, new GenericParser(), 4, 4, 4)
    {
        InstructionCreator.MaxRegNo = 15;
    }
    
    private static readonly Dictionary<string, InstructionCreator> Creators = new()
    {
        {".constants", new ConstantsInstructionCreator()},
        
        {"nop", new OpCode7InstructionCreator(InstructionCodes.Nop)},
        {"hlt", new OpCode7InstructionCreator(InstructionCodes.Hlt)},
        {"wfi", new OpCode7InstructionCreator(InstructionCodes.Wfi)},
        {"reti", new OpCode7InstructionCreator(InstructionCodes.Reti)},
        {"ret", new OpCode7InstructionCreator(InstructionCodes.Ret)},
        
        {"mov", new MovInstructionCreator()},
        {"lda", new LoadAddressInstructionCreator()},
        
        {"clr", new AluOneRegisterInstructionCreator(InstructionCodes.Xor)},
        {"ser", new AluWithImmediateInstructionCreator(InstructionCodes.Or, -1)},
        {"inc", new AluWithImmediateInstructionCreator(InstructionCodes.Add, 1)},
        {"dec", new AluWithImmediateInstructionCreator(InstructionCodes.Sub, 1)},
        {"shr", new AluInstructionCreator(InstructionCodes.Shr)},
        {"shl", new AluInstructionCreator(InstructionCodes.Shl)},
        {"ror", new AluInstructionCreator(InstructionCodes.Ror)},
        {"rol", new AluInstructionCreator(InstructionCodes.Rol)},
        {"test", new AluInstructionCreator(InstructionCodes.Test)},
        {"cmp", new AluInstructionCreator(InstructionCodes.Cmp)},
        {"add", new AluInstructionCreator(InstructionCodes.Add)},
        {"sub", new AluInstructionCreator(InstructionCodes.Sub)},
        {"adc", new AluInstructionCreator(InstructionCodes.Adc)},
        {"sbc", new AluInstructionCreator(InstructionCodes.Sbc)},
        {"and", new AluInstructionCreator(InstructionCodes.And)},
        {"or", new AluInstructionCreator(InstructionCodes.Or)},
        {"xor", new AluInstructionCreator(InstructionCodes.Xor)},
        {"mul", new AluInstructionCreator(InstructionCodes.Mul)},
        
        {"br", new BrInstructionCreator(Conditions.None)},
        {"bc", new BrInstructionCreator(Conditions.C)},
        {"blt", new BrInstructionCreator(Conditions.C)},
        {"bz", new BrInstructionCreator(Conditions.Z)},
        {"beq", new BrInstructionCreator(Conditions.Z)},
        {"bnc", new BrInstructionCreator(Conditions.NC)},
        {"bge", new BrInstructionCreator(Conditions.NC)},
        {"bnz", new BrInstructionCreator(Conditions.NZ)},
        {"bne", new BrInstructionCreator(Conditions.NZ)},
        {"bgt", new BrInstructionCreator(Conditions.GT)},
        {"ble", new BrInstructionCreator(Conditions.LE)},
        {"bmi", new BrInstructionCreator(Conditions.MI)},
        {"bpl", new BrInstructionCreator(Conditions.PL)},
        
        {"jmp", new JmpInstructionCreator(InstructionCodes.Jmp)},
        {"call", new JmpInstructionCreator(InstructionCodes.Call)},
        {"rcall", new OneRegisterInstructionCreator(InstructionCodes.RCall, false)},
        {"rjmp", new OneRegisterInstructionCreator(InstructionCodes.LoadPc, false)},
        {"loadsp", new OneRegisterInstructionCreator(InstructionCodes.LoadSp, false)},
        {"push", new OneRegisterInstructionCreator(InstructionCodes.Push, true)},
        {"pop", new OneRegisterInstructionCreator(InstructionCodes.Pop, false)},

        {"in", new TwoRegistersInstructionCreator(InstructionCodes.In, false, "in")},
        {"out", new TwoRegistersInstructionCreator(InstructionCodes.Out, true, "out")},
    };

    public void RegisterInstructionForImmediate(LoadImmediateInstruction instruction, uint immediate)
    {
        _loadConstantInstructionList.Add(new ImmediateInstructionInformation(instruction, new ConstantValue(immediate, null)));
    }

    public void RegisterInstructionForLabel(LoadImmediateInstruction instruction, string label)
    {
        _loadConstantInstructionList.Add(new ImmediateInstructionInformation(instruction, new ConstantValue(null, label)));
    }

    public uint[] GetConstants(uint pc)
    {
        List<uint> constants = [];
        foreach (var instruction in _loadConstantInstructions)
        {
            instruction.Instructions.ForEach(i => i.SetValue(pc));
            constants.Add(GetConstantValue(instruction.Value));
            pc++;
        }
        return constants.ToArray();
    }

    private uint GetConstantValue(ConstantValue value)
    {
        if (value.Immediate.HasValue)
            return value.Immediate.Value;
        var l = value.Label!;
        return FindLabel(l) ?? throw new Exception($"Label {l} not found");
    }

    public uint BuildConstants(uint pc)
    {
        _loadConstantInstructions = _loadConstantInstructionList.GroupBy(i => i.Value)
            .Select(g => 
                new ImmediateInstructions(g.Select(i => i.Instruction).ToList(), g.Key)).ToList();
        return (uint)_loadConstantInstructions.Count;
    }
}
