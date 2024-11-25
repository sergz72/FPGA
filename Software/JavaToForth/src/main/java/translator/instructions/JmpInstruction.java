package translator.instructions;

import java.util.Map;

public class JmpInstruction extends Instruction {
    public JmpInstruction(int bytecodePc, int opCode, int opCodeParameter, int to, String comment) {
        super(null, 2, bytecodePc, comment);
        code[0] = (opCode << 8) | opCodeParameter;
        code[1] = to;
    }

    public void updateOffset(int pc, Map<Integer, Integer> pcMapping) {
        var jmpTo = pcMapping.get(code[1]);
        code[1] = (jmpTo - pc - 1) & 0xFFFF;
    }

    public int getTo() {
        return code[1];
    }
}
