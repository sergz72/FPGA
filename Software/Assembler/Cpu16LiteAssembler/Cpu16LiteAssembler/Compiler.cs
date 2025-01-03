﻿using Cpu16LiteAssembler.Instructions;
using GenericAssembler;

namespace Cpu16LiteAssembler;

internal sealed class Cpu16Compiler: GenericCompiler
{
    internal Cpu16Compiler(List<string> sources, OutputFormat outputFormat): base(sources, outputFormat, Creators, new GenericParser())
    {
    }
        
    private static readonly Dictionary<string, InstructionCreator> Creators = new()
    {
        {"nop", new OpCodeInstructionCreator(InstructionCodes.Nop)},
        {"hlt", new OpCodeInstructionCreator(InstructionCodes.Hlt)},

        {"ret", new OpCodeInstructionCreator(InstructionCodes.Ret)},
        {"retc", new OpCodeInstructionCreator(InstructionCodes.Retc)},
        {"retlt", new OpCodeInstructionCreator(InstructionCodes.Retc)},
        {"retz", new OpCodeInstructionCreator(InstructionCodes.Retz)},
        {"reteq", new OpCodeInstructionCreator(InstructionCodes.Retz)},
        {"retnc", new OpCodeInstructionCreator(InstructionCodes.Retnc)},
        {"retge", new OpCodeInstructionCreator(InstructionCodes.Retnc)},
        {"retnz", new OpCodeInstructionCreator(InstructionCodes.Retnz)},
        {"retne", new OpCodeInstructionCreator(InstructionCodes.Retnz)},
        {"retgt", new OpCodeInstructionCreator(InstructionCodes.RetGt)},
        {"retle", new OpCodeInstructionCreator(InstructionCodes.RetLe)},
        {"retmi", new OpCodeInstructionCreator(InstructionCodes.RetMi)},
        {"retpl", new OpCodeInstructionCreator(InstructionCodes.RetPl)},

        {"reti", new OpCodeInstructionCreator(InstructionCodes.Reti)},
        {"retic", new OpCodeInstructionCreator(InstructionCodes.Retic)},
        {"retilt", new OpCodeInstructionCreator(InstructionCodes.Retic)},
        {"retiz", new OpCodeInstructionCreator(InstructionCodes.Retiz)},
        {"retieq", new OpCodeInstructionCreator(InstructionCodes.Retiz)},
        {"retinc", new OpCodeInstructionCreator(InstructionCodes.Retinc)},
        {"retige", new OpCodeInstructionCreator(InstructionCodes.Retinc)},
        {"retinz", new OpCodeInstructionCreator(InstructionCodes.Retinz)},
        {"retine", new OpCodeInstructionCreator(InstructionCodes.Retinz)},
        {"retigt", new OpCodeInstructionCreator(InstructionCodes.RetiGt)},
        {"retile", new OpCodeInstructionCreator(InstructionCodes.RetiLe)},
        {"retimi", new OpCodeInstructionCreator(InstructionCodes.RetiMi)},
        {"retipl", new OpCodeInstructionCreator(InstructionCodes.RetiPl)},
        
        {"mov", new MovInstructionCreator()},
        {"loada", new LoadAddressInstructionCreator()},
        {"loadf", new LoadfInstructionCreator()},
        
        {"clr", new RegisterLoadInstructionCreator(0)},
        {"ser", new RegisterLoadInstructionCreator(0xFFFF)},
        {"inc", new IncInstructionCreator()},
        {"dec", new DecInstructionCreator()},
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
        {"setf", new SetfRegisterInstructionCreator()},
        {"rlc", new AluInstructionCreator(AluOperations.Rlc)},
        {"rrc", new AluInstructionCreator(AluOperations.Rrc)},
        {"shlc", new AluInstructionCreator(AluOperations.Shlc)},
        {"shrc", new AluInstructionCreator(AluOperations.Shrc)},
        
        {"setc", new SetfImmediateInstructionCreator(4)},
        {"setz", new SetfImmediateInstructionCreator(2)},
        {"setn", new SetfImmediateInstructionCreator(1)},
        {"clrf", new SetfImmediateInstructionCreator(0)},
        
        {"in", new InInstructionCreator()},
        {"out", new OutInstructionCreator()},
        
        {"jmp", new JmpInstructionCreator(InstructionCodes.JmpAddr, InstructionCodes.JmpReg)},
        {"jmpc", new JmpInstructionCreator(InstructionCodes.JmpcAddr, InstructionCodes.JmpcReg)},
        {"jmplt", new JmpInstructionCreator(InstructionCodes.JmpcAddr, InstructionCodes.JmpcReg)},
        {"jmpz", new JmpInstructionCreator(InstructionCodes.JmpzAddr, InstructionCodes.JmpzReg)},
        {"jmpeq", new JmpInstructionCreator(InstructionCodes.JmpzAddr, InstructionCodes.JmpzReg)},
        {"jmpnc", new JmpInstructionCreator(InstructionCodes.JmpncAddr, InstructionCodes.JmpncReg)},
        {"jmpge", new JmpInstructionCreator(InstructionCodes.JmpncAddr, InstructionCodes.JmpncReg)},
        {"jmpnz", new JmpInstructionCreator(InstructionCodes.JmpnzAddr, InstructionCodes.JmpnzReg)},
        {"jmpne", new JmpInstructionCreator(InstructionCodes.JmpnzAddr, InstructionCodes.JmpnzReg)},
        {"jmpgt", new JmpInstructionCreator(InstructionCodes.JmpGtAddr, InstructionCodes.JmpGtReg)},
        {"jmple", new JmpInstructionCreator(InstructionCodes.JmpLeAddr, InstructionCodes.JmpLeReg)},
        {"jmpmi", new JmpInstructionCreator(InstructionCodes.JmpMiAddr, InstructionCodes.JmpMiReg)},
        {"jmppl", new JmpInstructionCreator(InstructionCodes.JmpPlAddr, InstructionCodes.JmpPlReg)},

        {"call", new JmpInstructionCreator(InstructionCodes.CallAddr, InstructionCodes.CallReg)},
        {"callc", new JmpInstructionCreator(InstructionCodes.CallcAddr, InstructionCodes.CallcReg)},
        {"calllt", new JmpInstructionCreator(InstructionCodes.CallcAddr, InstructionCodes.CallcReg)},
        {"callz", new JmpInstructionCreator(InstructionCodes.CallzAddr, InstructionCodes.CallzReg)},
        {"calleq", new JmpInstructionCreator(InstructionCodes.CallzAddr, InstructionCodes.CallzReg)},
        {"callnc", new JmpInstructionCreator(InstructionCodes.CallncAddr, InstructionCodes.CallncReg)},
        {"callge", new JmpInstructionCreator(InstructionCodes.CallncAddr, InstructionCodes.CallncReg)},
        {"callnz", new JmpInstructionCreator(InstructionCodes.CallnzAddr, InstructionCodes.CallnzReg)},
        {"callne", new JmpInstructionCreator(InstructionCodes.CallnzAddr, InstructionCodes.CallnzReg)},
        {"callgt", new JmpInstructionCreator(InstructionCodes.CallGtAddr, InstructionCodes.CallGtReg)},
        {"callle", new JmpInstructionCreator(InstructionCodes.CallLeAddr, InstructionCodes.CallLeReg)},
        {"callmi", new JmpInstructionCreator(InstructionCodes.CallMiAddr, InstructionCodes.CallMiReg)},
        {"callpl", new JmpInstructionCreator(InstructionCodes.CallPlAddr, InstructionCodes.CallPlReg)}
    };
}