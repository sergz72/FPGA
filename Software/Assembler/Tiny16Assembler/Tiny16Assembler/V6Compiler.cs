using GenericAssembler;
using Tiny16Assembler.V6Instructions;

namespace Tiny16Assembler;

internal sealed class Tiny16V6Compiler : GenericCompiler
{
    internal Tiny16V6Compiler(List<string> sources, OutputFormat outputFormat) :
        base(sources, outputFormat, Creators, new GenericParser(), 2, 2, 2)
    {
        InstructionCreator.MaxRegNo = 15;
    }
    
    private static readonly Dictionary<string, InstructionCreator> Creators = new()
    {
        {"nop", new OpCode7InstructionCreator(InstructionCodes.Nop)},
        {"hlt", new OpCode7InstructionCreator(InstructionCodes.Hlt)},
        {"wfi", new OpCode7InstructionCreator(InstructionCodes.Wfi)},
        {"reti", new OpCode7InstructionCreator(InstructionCodes.Reti)},
        {"ret", new OpCode7InstructionCreator(InstructionCodes.Ret)},
        
        {"mov", new MovInstructionCreator()},
        
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
        {"rcall", new OneRegisterInstructionCreator(InstructionCodes.RCall)},
        {"rjmp", new OneRegisterInstructionCreator(InstructionCodes.LoadPc)},
        {"loadsp", new OneRegisterInstructionCreator(InstructionCodes.LoadSp)},
        {"push", new OneRegisterInstructionCreator(InstructionCodes.Push)},
        {"pop", new OneRegisterInstructionCreator(InstructionCodes.Pop)},

        {"in", new TwoRegistersInstructionCreator(InstructionCodes.In)},
        {"out", new TwoRegistersInstructionCreator(InstructionCodes.Out)},
    };
}
