﻿using GenericAssembler;

namespace Tiny16Assembler.V2Instructions;

internal sealed class RegisterLoadInstructionCreator(uint adder) : InstructionCreator
{
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        if (parameters.Count != 1 || parameters[0].Type != TokenType.Name ||
            !GetRegisterNumber(compiler, parameters[0].StringValue, out var regNo))
            throw new InstructionException("register name expected");
        //return new MovInstruction(line, InstructionCodes.MovImmediate, regNo, adder, 0);
        throw new NotImplementedException();
    }
}
