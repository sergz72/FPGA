using GenericAssembler;

namespace Tiny16Assembler.V2Instructions;

internal sealed class JmpInstruction: Instruction
{
    internal JmpInstruction(string line, string file, int lineNo, uint opcode, uint condition, uint regNo, MemoryOp? memoryOp) :
        base(line, file, lineNo)
    {
    }

    public override uint[] BuildCode(uint labelAddress, uint pc)
    {
        throw new NotImplementedException();
    }
}

internal sealed class JmpInstructionCreator : InstructionCreator
{
    private bool _call;
    private uint _condition;
    internal JmpInstructionCreator(bool call, uint condition)
    {
        _call = call;
        _condition = condition;
    }
    
    public override Instruction Create(ICompiler compiler, string line, string file, int lineNo, List<Token> parameters)
    {
        var start = 0;
        if (InstructionsHelper.GetRegisterNumberWithMemoryFlag(compiler, parameters, ref start, out var regNo, 
                                                                out var memoryOp))
        {
            if (memoryOp == null)
                return new JmpInstruction(line , file, lineNo, _call ? InstructionCodes.CallReg : InstructionCodes.JmpReg,
                                            _condition, regNo, null);
            return new JmpInstruction(line, file, lineNo, _call ? InstructionCodes.CallPReg : InstructionCodes.JmpPReg,
                                        _condition, regNo, null);
        }
        if (parameters.Count != 1 || parameters[0].Type != TokenType.Name)
            throw new InstructionException("label name expected");
        //return new JmpInstruction(line, addrCode, 0, 0, parameters[0].StringValue);
        throw new NotImplementedException();
    }
}
