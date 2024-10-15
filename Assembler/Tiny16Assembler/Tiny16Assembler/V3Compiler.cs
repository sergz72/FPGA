using GenericAssembler;
using Tiny16Assembler.V3Instructions;

namespace Tiny16Assembler;

internal sealed class Tiny16V3Compiler : GenericCompiler
{
    internal Tiny16V3Compiler(List<string> sources, string outputFileName, OutputFormat outputFormat) :
        base(sources, outputFileName, outputFormat, Creators, new GenericParser(), 4)
    {
    }
    
    private static readonly Dictionary<string, InstructionCreator> Creators = new()
    {
        {"nop", new OpCodeInstructionCreator(InstructionCodes.OpcodeForOpcode12Commands, InstructionCodes.Nop)},
        {"hlt", new OpCodeInstructionCreator(InstructionCodes.OpcodeForOpcode12Commands, InstructionCodes.Hlt)},
        {"wfi", new OpCodeInstructionCreator(InstructionCodes.OpcodeForOpcode12Commands, InstructionCodes.Wfi)},
        {"reti", new OpCodeInstructionCreator(InstructionCodes.OpcodeForOpcode12Commands, InstructionCodes.Reti)},
        
        {"mv", new RegisterInstructionCreator(InstructionCodes.OpcodeForOpcode12Commands, InstructionCodes.Mv)},
        {"lui", new ImmediateInstructionCreator(InstructionCodes.Lui)},
        {"li", new LoadImmediateInstructionCreator()},
        {"la", new LoadAddressInstructionCreator()},
        
        {"clr", new RegisterInstructionCreator(InstructionCodes.OpcodeForOpcode12Commands, InstructionCodes.Xor)},
        {"ser", new SingleRegisterInstructionCreator(InstructionCodes.Or, 0xFF, 3)},
        {"inc", new SingleRegisterInstructionCreator(InstructionCodes.Adi, 1, 0)},
        {"dec", new SingleRegisterInstructionCreator(InstructionCodes.Adi, 0xFF, 3)},
        {"not", new SingleRegisterInstructionCreator(InstructionCodes.Xori, 0xFF, 3)},
        {"shr", new SingleRegisterInstructionCreator(InstructionCodes.OpcodeForOpcode12Commands, InstructionCodes.Shl, 0)},
        {"shl", new SingleRegisterInstructionCreator(InstructionCodes.OpcodeForOpcode12Commands, InstructionCodes.Shr, 0)},

        {"testi", new ImmediateInstructionCreator(InstructionCodes.Testi)},
        {"test", new RegisterInstructionCreator(InstructionCodes.OpcodeForOpcode12Commands, InstructionCodes.Test)},
        {"cmpi", new ImmediateInstructionCreator(InstructionCodes.Cmpi)},
        {"cmp", new RegisterInstructionCreator(InstructionCodes.OpcodeForOpcode12Commands, InstructionCodes.Cmp)},
        {"addi", new ImmediateInstructionCreator(InstructionCodes.Adi)},
        {"add", new RegisterInstructionCreator(InstructionCodes.OpcodeForOpcode12Commands, InstructionCodes.Add)},
        {"sub", new RegisterInstructionCreator(InstructionCodes.OpcodeForOpcode12Commands, InstructionCodes.Sub)},
        {"andi", new ImmediateInstructionCreator(InstructionCodes.Andi)},
        {"and", new RegisterInstructionCreator(InstructionCodes.OpcodeForOpcode12Commands, InstructionCodes.And)},
        {"ori", new ImmediateInstructionCreator(InstructionCodes.Ori)},
        {"or", new RegisterInstructionCreator(InstructionCodes.OpcodeForOpcode12Commands, InstructionCodes.Or)},
        {"xori", new ImmediateInstructionCreator(InstructionCodes.Xori)},
        {"xor", new RegisterInstructionCreator(InstructionCodes.OpcodeForOpcode12Commands, InstructionCodes.Xor)},
        
        {"b", new BrInstructionCreator(Conditions.None)},
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
        
        {"j", new JmpInstructionCreator()},
        {"jal", new JalInstructionCreator()},
        {"jalr", new RegisterInstructionCreator(InstructionCodes.OpcodeForOpcode12Commands, InstructionCodes.JalReg)},
        {"loadpc", new LoadPCInstructionCreator()},

        {"lw", new LoadStoreInstructionCreator(InstructionCodes.Lw)},
        {"sw", new LoadStoreInstructionCreator(InstructionCodes.Sw)},
    };
}
