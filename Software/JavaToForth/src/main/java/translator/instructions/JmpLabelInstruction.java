package translator.instructions;

public class JmpLabelInstruction extends Instruction {
    protected JmpLabelInstruction(Integer bytecodePc, String name) {
        super(name, 2, bytecodePc, "jmp " + name);
    }

    @Override
    public void buildCode(int labelAddress, int pc) {
        code[0]= InstructionGenerator.JMP << 8;
        code[1] = labelAddress -pc - 1;
    }
}
