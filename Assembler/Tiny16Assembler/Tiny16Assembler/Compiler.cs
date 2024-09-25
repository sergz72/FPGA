﻿using Tiny16Assembler.Instructions;
using GenericAssembler;

namespace Tiny16Assembler;

internal sealed class Tiny16Compiler: GenericCompiler
{
    internal Tiny16Compiler(List<string> sources, string outputFileName, OutputFormat outputFormat, bool noDiv32,
        			bool noRem32, bool noMul, bool noDiv16, bool noRem16):
        base(sources, outputFileName, outputFormat, Creators, new GenericParser())
    {
        /*if (!noDiv32)
            Creators.Add("div", new AluInstructionCreator(AluOperations.Div3216));
        if (!noRem32)
            Creators.Add("rem", new AluInstructionCreator(AluOperations.Rem3216));
        if (!noMul)
            Creators.Add("mul", new AluInstructionCreator(AluOperations.Mul));
        if (!noDiv16)
            Creators.Add("div", new AluInstructionCreator(AluOperations.Div1616));
        if (!noRem16)
            Creators.Add("rem", new AluInstructionCreator(AluOperations.Rem1616));*/

        RegisterNames["sp"] = "r15";
    }
        
    private static readonly Dictionary<string, InstructionCreator> Creators = new()
    {
        {"nop", new OpCodeInstructionCreator(InstructionCodes.Nop)},
        {"hlt", new OpCodeInstructionCreator(InstructionCodes.Hlt)},

        {"ret", new OpCodeInstructionCreator(InstructionCodes.Ret, Conditions.None)},
        {"retc", new OpCodeInstructionCreator(InstructionCodes.Ret, Conditions.C)},
        {"retlt", new OpCodeInstructionCreator(InstructionCodes.Ret, Conditions.C)},
        {"retz", new OpCodeInstructionCreator(InstructionCodes.Ret, Conditions.Z)},
        {"reteq", new OpCodeInstructionCreator(InstructionCodes.Ret, Conditions.Z)},
        {"retnc", new OpCodeInstructionCreator(InstructionCodes.Ret, Conditions.NC)},
        {"retge", new OpCodeInstructionCreator(InstructionCodes.Ret, Conditions.NC)},
        {"retnz", new OpCodeInstructionCreator(InstructionCodes.Ret, Conditions.NZ)},
        {"retne", new OpCodeInstructionCreator(InstructionCodes.Ret, Conditions.NZ)},
        {"retgt", new OpCodeInstructionCreator(InstructionCodes.Ret, Conditions.GT)},
        {"retle", new OpCodeInstructionCreator(InstructionCodes.Ret, Conditions.LE)},
        {"retmi", new OpCodeInstructionCreator(InstructionCodes.Ret, Conditions.MI)},
        {"retpl", new OpCodeInstructionCreator(InstructionCodes.Ret, Conditions.PL)},

        {"reti", new OpCodeInstructionCreator(InstructionCodes.Reti, Conditions.None)},
        {"retic", new OpCodeInstructionCreator(InstructionCodes.Reti, Conditions.C)},
        {"retilt", new OpCodeInstructionCreator(InstructionCodes.Reti, Conditions.C)},
        {"retiz", new OpCodeInstructionCreator(InstructionCodes.Reti, Conditions.Z)},
        {"retieq", new OpCodeInstructionCreator(InstructionCodes.Reti, Conditions.Z)},
        {"retinc", new OpCodeInstructionCreator(InstructionCodes.Reti, Conditions.NC)},
        {"retige", new OpCodeInstructionCreator(InstructionCodes.Reti, Conditions.NC)},
        {"retinz", new OpCodeInstructionCreator(InstructionCodes.Reti, Conditions.NZ)},
        {"retine", new OpCodeInstructionCreator(InstructionCodes.Reti, Conditions.NZ)},
        {"retigt", new OpCodeInstructionCreator(InstructionCodes.Reti, Conditions.GT)},
        {"retile", new OpCodeInstructionCreator(InstructionCodes.Reti, Conditions.LE)},
        {"retimi", new OpCodeInstructionCreator(InstructionCodes.Reti, Conditions.MI)},
        {"retipl", new OpCodeInstructionCreator(InstructionCodes.Reti, Conditions.PL)},
        
        {"mov", new MovInstructionCreator()},
        {"mvil", new MviInstructionCreator(InstructionCodes.Mvil)},
        {"mvih", new MviInstructionCreator(InstructionCodes.Mvih)},
        //{"loada", new LoadAddressInstructionCreator()},
        //{"loadf", new LoadfInstructionCreator()},
        
        //{"clr", new RegisterLoadInstructionCreator(0)},
        //{"ser", new RegisterLoadInstructionCreator(0xFFFF)},
        //{"inc", new IncInstructionCreator()},
        //{"dec", new DecInstructionCreator()},
        //{"not", new AluImmediateInstructionCreator(AluOperations.Xor, 0xFFFF)},

        //{"test", new AluInstructionCreator(AluOperations.Test)},
        //{"neg", new AluInstructionCreator(AluOperations.Neg)},
        //{"cmp", new AluInstructionCreator(AluOperations.Cmp)},
        //{"add", new AluInstructionCreator(AluOperations.Add)},
        //{"adc", new AluInstructionCreator(AluOperations.Adc)},
        //{"sub", new AluInstructionCreator(AluOperations.Sub)},
        //{"sbc", new AluInstructionCreator(AluOperations.Sbc)},
        //{"shl", new AluInstructionCreator(AluOperations.Shl)},
        //{"shr", new AluInstructionCreator(AluOperations.Shr)},
        //{"and", new AluInstructionCreator(AluOperations.And)},
        //{"or", new AluInstructionCreator(AluOperations.Or)},
        //{"xor", new AluInstructionCreator(AluOperations.Xor)},
        //{"setf", new SetfRegisterInstructionCreator()},
        //{"rlc", new AluInstructionCreator(AluOperations.Rlc)},
        //{"rrc", new AluInstructionCreator(AluOperations.Rrc)},
        //{"shlc", new AluInstructionCreator(AluOperations.Shlc)},
        //{"shrc", new AluInstructionCreator(AluOperations.Shrc)},
        
        //{"setc", new SetfImmediateInstructionCreator(4)},
        //{"setz", new SetfImmediateInstructionCreator(2)},
        //{"setn", new SetfImmediateInstructionCreator(1)},
        //{"clrf", new SetfImmediateInstructionCreator(0)},

        {"int", new IntInstructionCreator()},
        
        {"br", new BrInstructionCreator(Conditions.None)},
        {"brc", new BrInstructionCreator(Conditions.C)},
        {"brlt", new BrInstructionCreator(Conditions.C)},
        {"brz", new BrInstructionCreator(Conditions.Z)},
        {"breq", new BrInstructionCreator(Conditions.Z)},
        {"brnc", new BrInstructionCreator(Conditions.NC)},
        {"brge", new BrInstructionCreator(Conditions.NC)},
        {"brnz", new BrInstructionCreator(Conditions.NZ)},
        {"brne", new BrInstructionCreator(Conditions.NZ)},
        {"brgt", new BrInstructionCreator(Conditions.GT)},
        {"brle", new BrInstructionCreator(Conditions.LE)},
        {"brmi", new BrInstructionCreator(Conditions.MI)},
        {"brpl", new BrInstructionCreator(Conditions.PL)},
        
        {"jmp", new JmpInstructionCreator(false, Conditions.None)},
        {"jmpc", new JmpInstructionCreator(false, Conditions.C)},
        {"jmplt", new JmpInstructionCreator(false, Conditions.C)},
        {"jmpz", new JmpInstructionCreator(false, Conditions.Z)},
        {"jmpeq", new JmpInstructionCreator(false, Conditions.Z)},
        {"jmpnc", new JmpInstructionCreator(false, Conditions.NC)},
        {"jmpge", new JmpInstructionCreator(false, Conditions.NC)},
        {"jmpnz", new JmpInstructionCreator(false, Conditions.NZ)},
        {"jmpne", new JmpInstructionCreator(false, Conditions.NZ)},
        {"jmpgt", new JmpInstructionCreator(false, Conditions.GT)},
        {"jmple", new JmpInstructionCreator(false, Conditions.LE)},
        {"jmpmi", new JmpInstructionCreator(false, Conditions.MI)},
        {"jmppl", new JmpInstructionCreator(false, Conditions.PL)},
        
        {"call", new JmpInstructionCreator(true, Conditions.None)},
        {"callc", new JmpInstructionCreator(true, Conditions.C)},
        {"calllt", new JmpInstructionCreator(true, Conditions.C)},
        {"callz", new JmpInstructionCreator(true, Conditions.Z)},
        {"calleq", new JmpInstructionCreator(true, Conditions.Z)},
        {"callnc", new JmpInstructionCreator(true, Conditions.NC)},
        {"callge", new JmpInstructionCreator(true, Conditions.NC)},
        {"callnz", new JmpInstructionCreator(true, Conditions.NZ)},
        {"callne", new JmpInstructionCreator(true, Conditions.NZ)},
        {"callgt", new JmpInstructionCreator(true, Conditions.GT)},
        {"callle", new JmpInstructionCreator(true, Conditions.LE)},
        {"callmi", new JmpInstructionCreator(true, Conditions.MI)},
        {"callpl", new JmpInstructionCreator(true, Conditions.PL)},
    };
}