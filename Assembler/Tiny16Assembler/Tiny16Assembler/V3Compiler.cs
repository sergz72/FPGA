using GenericAssembler;
using Tiny16Assembler.V3Instructions;

namespace Tiny16Assembler;

internal sealed class Tiny16V3Compiler : GenericCompiler
{
    internal Tiny16V3Compiler(List<string> sources, OutputFormat outputFormat) :
        base(sources, outputFormat, Creators, new GenericParser(), 4)
    {
    }
    
    private static readonly Dictionary<string, InstructionCreator> Creators = new()
    {
        {".var", new VarCreator()},
        {"nop", new OpCodeInstructionCreator(InstructionCodes.OpcodeForOpcode12Commands, InstructionCodes.Nop)},
        {"hlt", new OpCodeInstructionCreator(InstructionCodes.OpcodeForOpcode12Commands, InstructionCodes.Hlt)},
        {"wfi", new OpCodeInstructionCreator(InstructionCodes.OpcodeForOpcode12Commands, InstructionCodes.Wfi)},
        {"reti", new OpCodeInstructionCreator(InstructionCodes.OpcodeForOpcode12Commands, InstructionCodes.Reti)},
        
        {"mv", new RegisterInstructionCreator(InstructionCodes.OpcodeForOpcode12Commands, InstructionCodes.Mv)},
        {"lli", new ImmediateInstructionCreator(InstructionCodes.Lli)},
        {"li", new LoadImmediateInstructionCreator()},
        {"la", new LoadAddressInstructionCreator()},
        
        {"clr", new RegisterInstructionCreator(InstructionCodes.OpcodeForOpcode12Commands, InstructionCodes.Xor)},
        {"shr", new SingleRegisterInstructionCreator(InstructionCodes.OpcodeForOpcode12Commands, InstructionCodes.Shl, 0)},
        {"shl", new SingleRegisterInstructionCreator(InstructionCodes.OpcodeForOpcode12Commands, InstructionCodes.Shr, 0)},

        {"test", new RegisterInstructionCreator(InstructionCodes.OpcodeForOpcode12Commands, InstructionCodes.Test)},
        {"cmp", new RegisterInstructionCreator(InstructionCodes.OpcodeForOpcode12Commands, InstructionCodes.Cmp)},
        {"add", new RegisterInstructionCreator(InstructionCodes.OpcodeForOpcode12Commands, InstructionCodes.Add)},
        {"sub", new RegisterInstructionCreator(InstructionCodes.OpcodeForOpcode12Commands, InstructionCodes.Sub)},
        {"and", new RegisterInstructionCreator(InstructionCodes.OpcodeForOpcode12Commands, InstructionCodes.And)},
        {"or", new RegisterInstructionCreator(InstructionCodes.OpcodeForOpcode12Commands, InstructionCodes.Or)},
        {"xor", new RegisterInstructionCreator(InstructionCodes.OpcodeForOpcode12Commands, InstructionCodes.Xor)},
        {"swab", new RegisterInstructionCreator(InstructionCodes.OpcodeForOpcode12Commands, InstructionCodes.Swab)},
        {"mul", new RegisterInstructionCreator(InstructionCodes.OpcodeForOpcode12Commands, InstructionCodes.Mul)},
        {"div", new RegisterInstructionCreator(InstructionCodes.OpcodeForOpcode12Commands, InstructionCodes.Div)},
        {"rem", new RegisterInstructionCreator(InstructionCodes.OpcodeForOpcode12Commands, InstructionCodes.Rem)},
        
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
        {"j16", new Jmp16InstructionCreator()},
        {"jal", new JalInstructionCreator()},
        {"jalr", new RegisterInstructionCreator(InstructionCodes.OpcodeForOpcode12Commands, InstructionCodes.JalReg)},
        {"loadpc", new LoadPCInstructionCreator()},

        {"lw", new LoadStoreInstructionCreator(InstructionCodes.Lw)},
        {"sw", new LoadStoreInstructionCreator(InstructionCodes.Sw)},
    };
}
