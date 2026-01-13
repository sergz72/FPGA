using GenericAssembler;
using Tiny16Assembler.V7Instructions;

namespace Tiny16Assembler;

internal sealed class Tiny16V7Compiler : GenericCompiler
{
    internal Tiny16V7Compiler(List<string> sources, OutputFormat outputFormat) :
        base(sources, outputFormat, Creators, new GenericParser(), 2, 4, 4)
    {
        InstructionCreator.MaxRegNo = 255;
    }
    
    private static readonly Dictionary<string, InstructionCreator> Creators = new()
    {
        {"hlt", new OneByteInstructionCreator(InstructionCodes.Hlt)},
        {"wfi", new OneByteInstructionCreator(InstructionCodes.Wfi)},
        {"reti", new OneByteInstructionCreator(InstructionCodes.Reti)},
        
        {"mov", new AluInstructionCreator(InstructionCodes.Mov)},
        {"cmp", new AluInstructionCreator(InstructionCodes.Cmp)},
        {"add", new AluInstructionCreator(InstructionCodes.Add)},
        {"sub", new AluInstructionCreator(InstructionCodes.Sub)},
        {"adc", new AluInstructionCreator(InstructionCodes.Adc)},
        {"sbc", new AluInstructionCreator(InstructionCodes.Sbc)},
        {"and", new AluInstructionCreator(InstructionCodes.And)},
        {"or", new AluInstructionCreator(InstructionCodes.Or)},
        {"xor", new AluInstructionCreator(InstructionCodes.Xor)},
        {"test", new AluInstructionCreator(InstructionCodes.Test)},

        {"lda", new LoadAddressInstructionCreator(InstructionCodes.Mov)},
        {"adda", new LoadAddressInstructionCreator(InstructionCodes.Add)},
        
        {"clr", new OneRegisterInstructionCreator(InstructionCodes.Clr|InstructionCodes.AluOp)},
        {"ser", new OneRegisterInstructionCreator(InstructionCodes.Set|InstructionCodes.AluOp)},
        {"inc", new OneRegisterInstructionCreator(InstructionCodes.Inc|InstructionCodes.AluOp)},
        {"dec", new OneRegisterInstructionCreator(InstructionCodes.Dec|InstructionCodes.AluOp)},
        {"not", new OneRegisterInstructionCreator(InstructionCodes.Not|InstructionCodes.AluOp)},
        {"neg", new OneRegisterInstructionCreator(InstructionCodes.Neg|InstructionCodes.AluOp)},
        {"shr", new OneRegisterInstructionCreator(InstructionCodes.Shr|InstructionCodes.AluOp)},
        {"shl", new OneRegisterInstructionCreator(InstructionCodes.Shl|InstructionCodes.AluOp)},
        {"ror", new OneRegisterInstructionCreator(InstructionCodes.Ror|InstructionCodes.AluOp)},
        {"rol", new OneRegisterInstructionCreator(InstructionCodes.Rol|InstructionCodes.AluOp)},
        {"swab", new OneRegisterInstructionCreator(InstructionCodes.Swab|InstructionCodes.AluOp)},

        {"clc", new OneByteInstructionCreator(InstructionCodes.Clc)},
        {"stc", new OneByteInstructionCreator(InstructionCodes.Stc)},
        
        {"br", new BrInstructionCreator(Conditions.None)},
        {"bcs", new BrInstructionCreator(Conditions.C)},
        {"blt", new BrInstructionCreator(Conditions.C)},
        {"beq", new BrInstructionCreator(Conditions.Z)},
        {"bcc", new BrInstructionCreator(Conditions.NC)},
        {"bge", new BrInstructionCreator(Conditions.NC)},
        {"bne", new BrInstructionCreator(Conditions.NZ)},
        {"bgt", new BrInstructionCreator(Conditions.GT)},
        {"ble", new BrInstructionCreator(Conditions.LE)},
        {"bmi", new BrInstructionCreator(Conditions.MI)},
        {"bpl", new BrInstructionCreator(Conditions.PL)},
        
        {"jmp", new JmpInstructionCreator()},
        {"jal", new JalInstructionCreator()},
        {"jalr", new OneRegisterInstructionCreator(InstructionCodes.Jalr)},
        {"rjmp", new OneRegisterInstructionCreator(InstructionCodes.RJmp)},

        {"in", new InInstructionCreator()},
        {"out", new OutInstructionCreator()},
        
        {"sb", new StoreInstructionCreator(InstructionCodes.Sb)},
        {"sw", new StoreInstructionCreator(InstructionCodes.Sw)},
        {"lb", new LoadInstructionCreator(InstructionCodes.Lb)},
        {"lbu", new LoadInstructionCreator(InstructionCodes.Lbu)},
        {"lw", new LoadInstructionCreator(InstructionCodes.Lw)},
    };
}
