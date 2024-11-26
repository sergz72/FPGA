package translator.instructions;

public class JmpOffsetInstruction extends Instruction {
    public JmpOffsetInstruction(int bytecodePc, int opCode, int opCodeParameter, int offset, String comment) {
        super(null, 2, bytecodePc, comment);
        code[0] = (opCode << 8) | opCodeParameter;
        code[1] = offset;
    }
}