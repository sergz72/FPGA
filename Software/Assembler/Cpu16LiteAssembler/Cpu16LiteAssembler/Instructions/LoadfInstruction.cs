﻿using GenericAssembler;

namespace Cpu16LiteAssembler.Instructions;

internal sealed class LoadfInstruction : Instruction
{
    private readonly uint _regNo;
    
    internal LoadfInstruction(string line, string file, int lineNo, uint regNo): base(line, file, lineNo)
    {
        _regNo = regNo;
    }
    
    public override uint[] BuildCode(uint labelAddress, uint pc)
    {
        return [InstructionCodes.Loadf | (_regNo << 8)];
    }
}

internal sealed class LoadfInstructionCreator : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        if (parameters.Count == 0 || parameters[0].Type != TokenType.Name)
            throw new InstructionException("register name expected");
        if (!GetRegisterNumber(compiler, parameters[0].StringValue, out var regNo))
            throw new InstructionException("register name expected");
        return new LoadfInstruction(line, file, lineNo, regNo);
    }
}
