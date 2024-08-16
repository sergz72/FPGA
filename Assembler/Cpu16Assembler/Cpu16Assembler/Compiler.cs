using Cpu16Assembler.Instructions;
using GenericAssembler;

namespace Cpu16Assembler;

internal sealed class Cpu16Compiler: GenericCompiler
{
    internal Cpu16Compiler(List<string> sources, string outputFileName, OutputFormat outputFormat, bool noDiv,
        bool noRem, bool noMul): base(sources, outputFileName, outputFormat, Creators, new GenericParser())
    {
        if (!noDiv)
            Creators.Add("div", new AluInstructionCreator(AluOperations.Div));
        if (!noRem)
            Creators.Add("rem", new AluInstructionCreator(AluOperations.Rem));
        if (!noMul)
            Creators.Add("mul", new AluInstructionCreator(AluOperations.Mul));
    }
        
    private static readonly Dictionary<string, InstructionCreator> Creators = new()
    {
        {"nop", new OpCodeInstructionCreator(InstructionCodes.Nop)},
        {"hlt", new OpCodeInstructionCreator(InstructionCodes.Hlt)},

        {"ret", new OpCodeInstructionCreator(InstructionCodes.Ret)},
        {"retc", new OpCodeInstructionCreator(InstructionCodes.Retc)},
        {"retz", new OpCodeInstructionCreator(InstructionCodes.Retz)},
        {"retnc", new OpCodeInstructionCreator(InstructionCodes.Retnc)},
        {"retnz", new OpCodeInstructionCreator(InstructionCodes.Retnz)},
        {"retgt", new OpCodeInstructionCreator(InstructionCodes.RetGt)},
        {"retle", new OpCodeInstructionCreator(InstructionCodes.RetLe)},

        {"reti", new OpCodeInstructionCreator(InstructionCodes.Reti)},
        {"retic", new OpCodeInstructionCreator(InstructionCodes.Retic)},
        {"retiz", new OpCodeInstructionCreator(InstructionCodes.Retiz)},
        {"retinc", new OpCodeInstructionCreator(InstructionCodes.Retinc)},
        {"retinz", new OpCodeInstructionCreator(InstructionCodes.Retinz)},
        {"retigt", new OpCodeInstructionCreator(InstructionCodes.RetiGt)},
        {"retile", new OpCodeInstructionCreator(InstructionCodes.RetiLe)},
        
        {"mov", new MovInstructionCreator()},
        {"loadf", new LoadfInstructionCreator()},
        
        {"clr", new RegisterLoadInstructionCreator(0)},
        {"ser", new RegisterLoadInstructionCreator(0xFFFF)},
        {"inc", new AluImmediateInstructionCreator(AluOperations.Add, 1)},
        {"dec", new AluImmediateInstructionCreator(AluOperations.Add, 0xFFFF)},
        {"not", new AluImmediateInstructionCreator(AluOperations.Xor, 0xFFFF)},

        {"test", new AluInstructionCreator(AluOperations.Test)},
        {"neg", new AluInstructionCreator(AluOperations.Neg)},
        {"cmp", new AluInstructionCreator(AluOperations.Cmp)},
        {"add", new AluInstructionCreator(AluOperations.Add)},
        {"adc", new AluInstructionCreator(AluOperations.Adc)},
        {"sub", new AluInstructionCreator(AluOperations.Sub)},
        {"sbc", new AluInstructionCreator(AluOperations.Sbc)},
        {"shl", new AluInstructionCreator(AluOperations.Shl)},
        {"shr", new AluInstructionCreator(AluOperations.Shr)},
        {"and", new AluInstructionCreator(AluOperations.And)},
        {"or", new AluInstructionCreator(AluOperations.Or)},
        {"xor", new AluInstructionCreator(AluOperations.Xor)},
        {"setf", new AluInstructionCreator(AluOperations.Setf)},
        {"rlc", new AluInstructionCreator(AluOperations.Rlc)},
        {"rrc", new AluInstructionCreator(AluOperations.Rrc)},
        {"shlc", new AluInstructionCreator(AluOperations.Shlc)},
        {"shrc", new AluInstructionCreator(AluOperations.Shrc)},
        
        {"setc", new Setf2InstructionCreator(4)},
        {"setz", new Setf2InstructionCreator(2)},
        {"setn", new Setf2InstructionCreator(1)},
        {"clrf", new Setf2InstructionCreator(0)},
        
        {"in", new InInstructionCreator()},
        {"out", new OutInstructionCreator()},
        
        {"jmp", new JmpInstructionCreator(InstructionCodes.JmpAddr, InstructionCodes.JmpReg)},
        {"jmpc", new JmpInstructionCreator(InstructionCodes.JmpcAddr, InstructionCodes.JmpcReg)},
        {"jmpz", new JmpInstructionCreator(InstructionCodes.JmpzAddr, InstructionCodes.JmpzReg)},
        {"jmpnc", new JmpInstructionCreator(InstructionCodes.JmpncAddr, InstructionCodes.JmpncReg)},
        {"jmpnz", new JmpInstructionCreator(InstructionCodes.JmpnzAddr, InstructionCodes.JmpnzReg)},
        {"jmpgt", new JmpInstructionCreator(InstructionCodes.JmpGtAddr, InstructionCodes.JmpGtReg)},
        {"jmple", new JmpInstructionCreator(InstructionCodes.JmpLeAddr, InstructionCodes.JmpLeReg)},

        {"call", new JmpInstructionCreator(InstructionCodes.CallAddr, InstructionCodes.CallReg)},
        {"callc", new JmpInstructionCreator(InstructionCodes.CallcAddr, InstructionCodes.CallcReg)},
        {"callz", new JmpInstructionCreator(InstructionCodes.CallzAddr, InstructionCodes.CallzReg)},
        {"callnc", new JmpInstructionCreator(InstructionCodes.CallncAddr, InstructionCodes.CallncReg)},
        {"callnz", new JmpInstructionCreator(InstructionCodes.CallnzAddr, InstructionCodes.CallnzReg)},
        {"callgt", new JmpInstructionCreator(InstructionCodes.CallGtAddr, InstructionCodes.CallGtReg)},
        {"callle", new JmpInstructionCreator(InstructionCodes.CallLeAddr, InstructionCodes.CallLeReg)}
    };
}