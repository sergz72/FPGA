﻿using GenericAssembler;

namespace Tiny16Assembler.Instructions;

internal sealed class AluregisterInstruction : Instruction
{
    private readonly uint _aluOperation, _regNo, _value;
    
    internal AluregisterInstruction(string line, uint aluOperation, uint regNo, uint value): base(line)
    {
        _aluOperation = aluOperation;
        _regNo = regNo;
        _value = value;
    }
    
    public override uint[] BuildCode(uint labelAddress)
    {
        //return [_aluOperation | 0x80 | (_regNo << 8) | (_value << 16)];
        throw new NotImplementedException();
    }
}

internal sealed class AluRegisterInstructionCreator(uint aluOperation) : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, List<Token> parameters)
    {
        if (parameters.Count != 1 || parameters[0].Type != TokenType.Name ||
            !GetRegisterNumber(compiler, parameters[0].StringValue, out var regNo))
            throw new InstructionException("register name expected");
        //return new AluImmediateInstruction(line, aluOperation, regNo, value);
        throw new NotImplementedException();
    }
}