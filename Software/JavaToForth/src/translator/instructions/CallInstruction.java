package translator.instructions;

public class CallInstruction extends Instruction {
    protected CallInstruction(Integer bytecodePc, String name) {
        super(name, 3, bytecodePc, "call " + name);
    }

    @Override
    public void buildCode(int labelAddress, int pc) {
        code[0] = InstructionGenerator.CALL << 8;
        code[1] = labelAddress & 0xFFFF;
        code[2] = (labelAddress >> 16) & 0xFFFF;
    }
}
