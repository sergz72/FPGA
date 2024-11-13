package translator.instructions;

import java.lang.reflect.Array;

public class OpCodeInstruction extends Instruction {
    public OpCodeInstruction(int opCode, int opCodeParameter, int[] parameters, String comment) {
        super(null, parameters.length + 1, comment);
        code[0] = (opCode << 8) | (opCodeParameter & 0xFF);
        System.arraycopy(parameters, 0, code, 1, parameters.length);
    }
}
