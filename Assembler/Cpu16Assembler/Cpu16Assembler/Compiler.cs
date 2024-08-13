using Cpu16Assembler.Instructions;
using GenericAssembler;

namespace Cpu16Assembler;

internal sealed class Cpu16Compiler(List<string> sources, string outputFileName, OutputFormat outputFormat):
    GenericCompiler(sources, outputFileName, outputFormat, Creators, new GenericParser())
{
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
        {"mul", new AluInstructionCreator(AluOperations.Mul)},
        {"div", new AluInstructionCreator(AluOperations.Div)},
        {"rem", new AluInstructionCreator(AluOperations.Rem)},
        
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