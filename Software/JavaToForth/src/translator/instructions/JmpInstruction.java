package translator.instructions;

import java.util.Map;

public class JmpInstruction extends Instruction {
    private int offset, opCode;
    public JmpInstruction(int opCode, int to, String comment) {
        super(null, 3, comment);
        this.opCode = opCode;
        this.offset = to;
    }

    public void updateOffset(int pc, Map<Integer, Integer> pcMapping) {
        var jmpTo = pcMapping.get(offset);
        offset = jmpTo - pc;
    }
}
