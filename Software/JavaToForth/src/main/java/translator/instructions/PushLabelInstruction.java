package translator.instructions;

public class PushLabelInstruction extends Instruction {
    protected PushLabelInstruction(Integer bytecodePc, String name) {
        super(name, 3, bytecodePc, "push " + name);
    }

    @Override
    public void buildCode(int labelAddress, int pc) {
        code[0]= InstructionGenerator.PUSH << 8;
        code[1] = labelAddress & 0xFFFF;
        code[2] = (labelAddress >> 16) & 0xFFFF;
    }
}
