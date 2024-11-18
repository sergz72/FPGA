package translator.instructions;

public class LabelInstruction extends Instruction {
    public LabelInstruction(String name) {
        super(name, 1, null, name);
    }

    @Override
    public void buildCode(int labelAddress, int pc) {
        code[0] = labelAddress;
    }
}
