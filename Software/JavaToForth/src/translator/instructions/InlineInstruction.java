package translator.instructions;

public class InlineInstruction extends Instruction {
    public InlineInstruction(Integer bytecodePc, int[] code, String comment) {
        super(null, code.length, bytecodePc, comment);
        this.code = code;
    }
}
