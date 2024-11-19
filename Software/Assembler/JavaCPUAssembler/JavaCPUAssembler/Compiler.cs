using GenericAssembler;
using JavaCPUAssembler.Instructions;

namespace JavaCPUAssembler;

internal sealed class JavaCPUCompiler : GenericCompiler
{
    internal JavaCPUCompiler(List<string> sources) :
        base(sources, OutputFormat.Hex, Creators, new GenericParser(), 4, 8)
    {
    }
    
    private static readonly Dictionary<string, InstructionCreator> Creators = new()
    {
        {"add", new OpCodeInstructionCreator(InstructionCodes.AluOp, AluOperations.Add)},
        {"sub", new OpCodeInstructionCreator(InstructionCodes.AluOp, AluOperations.Sub)},
        {"and", new OpCodeInstructionCreator(InstructionCodes.AluOp, AluOperations.And)},
        {"or", new OpCodeInstructionCreator(InstructionCodes.AluOp, AluOperations.Or)},
        {"xor", new OpCodeInstructionCreator(InstructionCodes.AluOp, AluOperations.Xor)},
        {"shl", new OpCodeInstructionCreator(InstructionCodes.AluOp, AluOperations.Shl)},
        {"llshr", new OpCodeInstructionCreator(InstructionCodes.AluOp, AluOperations.LLShr)},
        {"ilshr", new OpCodeInstructionCreator(InstructionCodes.AluOp, AluOperations.ILShr)},
        {"ashr", new OpCodeInstructionCreator(InstructionCodes.AluOp, AluOperations.AShr)},
        {"bittest", new OpCodeInstructionCreator(InstructionCodes.AluOp, AluOperations.BitTest)},
        {"mul", new OpCodeInstructionCreator(InstructionCodes.AluOp, AluOperations.Mul)},
        {"cmp", new OpCodeInstructionCreator(InstructionCodes.AluOp, AluOperations.Cmp)},

        {"arrayp", new OpCodeInstructionCreator(InstructionCodes.Arrayp)},
        {"arrayp2", new OpCodeInstructionCreator(InstructionCodes.Arrayp2)},
        {"bpush", new OneParameterInstructionCreator(InstructionCodes.BPush)},
        {"call", new Label32InstructionCreator(InstructionCodes.Call)},
        {"dup", new OpCodeInstructionCreator(InstructionCodes.Dup)},
        {"drop", new OpCodeInstructionCreator(InstructionCodes.Drop)},
        {"drop2", new OpCodeInstructionCreator(InstructionCodes.Drop2)},
        {"getlocal", new OneParameterInstructionCreator(InstructionCodes.LocalGet)},
        {"getn", new OneParameterInstructionCreator(InstructionCodes.Getn)},
        {"getsp", new OpCodeInstructionCreator(InstructionCodes.GetDataStackPointer)},
        {"goto", new Label16InstructionCreator(InstructionCodes.Jmp, 0)},
        {"hlt", new OpCodeInstructionCreator(InstructionCodes.Hlt)},
        {"icall", new OneParameterInstructionCreator(InstructionCodes.CallIndirect)},
        {"ifcmpeq", new Label16InstructionCreator(InstructionCodes.IfCmp,Conditions.CMP_EQ)},
        {"ifcmpne", new Label16InstructionCreator(InstructionCodes.IfCmp,Conditions.CMP_NE)},
        {"ifcmpge", new Label16InstructionCreator(InstructionCodes.IfCmp,Conditions.CMP_GE)},
        {"ifcmpgt", new Label16InstructionCreator(InstructionCodes.IfCmp,Conditions.CMP_GT)},
        {"ifcmple", new Label16InstructionCreator(InstructionCodes.IfCmp,Conditions.CMP_LE)},
        {"ifcmplt", new Label16InstructionCreator(InstructionCodes.IfCmp,Conditions.CMP_LT)},
        {"ifeq", new Label16InstructionCreator(InstructionCodes.If,Conditions.EQ)},
        {"ifne", new Label16InstructionCreator(InstructionCodes.If,Conditions.NE)},
        {"ifge", new Label16InstructionCreator(InstructionCodes.If,Conditions.GE)},
        {"ifgt", new Label16InstructionCreator(InstructionCodes.If,Conditions.GT)},
        {"ifle", new Label16InstructionCreator(InstructionCodes.If,Conditions.LE)},
        {"iflt", new Label16InstructionCreator(InstructionCodes.If,Conditions.LT)},
        {"iget", new OpCodeInstructionCreator(InstructionCodes.Get)},
        {"inc", new TwoParametersInstructionCreator(InstructionCodes.Inc)},
        {"ipush", new PushInstructionCreator()},
        {"iset", new OpCodeInstructionCreator(InstructionCodes.Set)},
        {"lget", new OpCodeInstructionCreator(InstructionCodes.GetLong)},
        {"locals", new OneParameterInstructionCreator(InstructionCodes.Locals)},
        {"lpush", new PushLongInstructionCreator()},
        {"lset", new OpCodeInstructionCreator(InstructionCodes.SetLong)},
        {"neg", new OpCodeInstructionCreator(InstructionCodes.Neg)},
        {"nop", new OpCodeInstructionCreator(InstructionCodes.Nop)},
        {"over", new OpCodeInstructionCreator(InstructionCodes.Over)},
        {"push", new Label32InstructionCreator(InstructionCodes.Push)},
        {"reti", new OneParameterInstructionCreator(InstructionCodes.Reti)},
        {"ret", new OpCodeInstructionCreator(InstructionCodes.Ret)},
        {"retn", new OneParameterInstructionCreator(InstructionCodes.Retn)},
        {"rot", new OpCodeInstructionCreator(InstructionCodes.Rot)},
        {"setlocal", new OneParameterInstructionCreator(InstructionCodes.LocalSet)},
        {"spush", new PushShortInstructionCreator()},
        {"swap", new OpCodeInstructionCreator(InstructionCodes.Swap)},
        {"wfi", new OpCodeInstructionCreator(InstructionCodes.Wfi)},
    };
}
