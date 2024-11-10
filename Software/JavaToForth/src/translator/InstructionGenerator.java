package translator;

import java.util.ArrayList;
import java.util.List;

public class InstructionGenerator {
    private static final int PUSH = 0;
    private static final int DUP = 1;
    private static final int SET = 2;
    private static final int JMP = 3;
    private static final int GET = 4;
    private static final int CALL = 5;
    private static final int RET = 6;
    private static final int RETN = 7;
    private static final int HLT = 8;
    private static final int WFI = 9;
    private static final int BR = 10;
    private static final int BR0 = 11;
    private static final int RETI = 12;
    private static final int DROP = 13;
    private static final int SWAP = 14;
    private static final int ROT = 15;
    private static final int OVER = 16;
    private static final int LOCAL_GET = 20;
    private static final int LOCAL_SET = 21;
    private static final int LOCALS = 22;

    List<Integer> instructions;

    public InstructionGenerator() {
        instructions = new ArrayList<>();
    }

    public void addPush(int value)
    {
        instructions.add(PUSH);
        instructions.add(value);
    }

    public void addGet()
    {
        instructions.add(GET);
    }

    public void addGetLocal(int i) {
        instructions.add(LOCAL_GET);
        instructions.add(i);
    }
}
