package translator.instructions;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class InstructionGenerator {
    private static final int PUSH = 0;
    private static final int PUSH_LONG = 1;
    private static final int DUP = 2;
    private static final int SET = 3;
    private static final int SET_LONG = 4;
    private static final int JMP = 5;
    private static final int GET = 6;
    private static final int GET_LONG = 7;
    private static final int CALL = 8;
    private static final int CALL_INDIRECT = 9;
    private static final int RET = 10;
    private static final int RETN = 11;
    private static final int HLT = 12;
    private static final int WFI = 13;
    private static final int NEG = 14;
    private static final int INC = 15;
    private static final int RETI = 16;
    private static final int RETIN = 17;
    private static final int DROP = 18;
    private static final int DROP2 = 19;
    private static final int SWAP = 20;
    private static final int ROT = 21;
    private static final int OVER = 22;
    private static final int LOCAL_GET = 23;
    private static final int LOCAL_SET = 24;
    private static final int LOCALS = 25;
    private static final int NOP = 26;
    private static final int IFCMP = 0xD0;
    private static final int IF = 0xE0;
    private static final int ALU_OP = 0xF0;

    public static final int ALU_OP_ADD      = 0;
    public static final int ALU_OP_SUB      = 1;
    public static final int ALU_OP_AND      = 2;
    public static final int ALU_OP_OR       = 3;
    public static final int ALU_OP_XOR      = 4;
    public static final int ALU_OP_SHL      = 5;
    public static final int ALU_OP_LSHR     = 6;
    public static final int ALU_OP_ASHR     = 7;
    public static final int ALU_OP_BIT_TEST = 8;
    public static final int ALU_OP_MUL      = 9;
    public static final int ALU_OP_CMP      = 10;

    public static final int IF_EQ = 0;
    public static final int IF_NE = 1;
    public static final int IF_GT = 2;
    public static final int IF_GE = 3;
    public static final int IF_LT = 4;
    public static final int IF_LE = 5;

    List<Instruction> instructions;
    Map<Integer, Integer> pcMapping;

    public InstructionGenerator() {
        instructions = new ArrayList<>();
        pcMapping = new HashMap<>();
    }

    public void addPush(int value)
    {
        instructions.add(new OpCodeInstruction(PUSH, new int[]{value & 0xFFFF, value >> 16},
                            String.format("push %d %x", value, value)));
    }

    public void addPushLong(long value) {
        int v1 = (int)(value & 0xFFFF);
        int v2 = (int)(value >> 16);
        int v3 = (int)(value >> 32);
        int v4 = (int)(value >> 48);
        instructions.add(new OpCodeInstruction(PUSH_LONG, new int[]{v1, v2, v3, v4},
                String.format("push_long %d %x", value, value)));
    }

    public void addGet()
    {
        instructions.add(new OpCodeInstruction(GET, new int[0], "get"));
    }

    public void addDup()
    {
        instructions.add(new OpCodeInstruction(DUP, new int[0], "dup"));
    }

    public void addDup2()
    {
        instructions.add(new OpCodeInstruction(OVER, new int[]{OVER}, "dup2(over over)"));
    }

    public void addGetLocal(int i) {
        instructions.add(new OpCodeInstruction(LOCAL_GET, new int[]{i}, String.format("local_get %d", i)));
    }

    public void addSetLocal(int i) {
        instructions.add(new OpCodeInstruction(LOCAL_SET, new int[]{i}, String.format("local_set %d", i)));
    }

    public void addAluOp(int aluOp, String comment) {
        instructions.add(new OpCodeInstruction(ALU_OP|aluOp, new int[0], comment));
    }

    public void addIfcmp(int code, String comment, int index, int pc) {
        instructions.add(new JmpInstruction(IFCMP|code, pc + index, comment + " " + index));
    }

    public void addIf(int code, String comment, int index, int pc) {
        instructions.add(new JmpInstruction(IF|code, pc + index, comment + " " + index));
    }

    public void addInc(int index, int value) {
        instructions.add(new OpCodeInstruction(INC, new int[]{index,value}, String.format("inc %d %d", index, value)));
    }

    public void addNeg() {
        instructions.add(new OpCodeInstruction(NEG, new int[0], "neg"));
    }

    public void addNop() {
        instructions.add(new OpCodeInstruction(NOP, new int[0], "nop"));
    }

    public void addDrop() {
        instructions.add(new OpCodeInstruction(DROP, new int[0], "drop"));
    }

    public void addDrop2() {
        instructions.add(new OpCodeInstruction(DROP2, new int[0], "drop2"));
    }

    public void addSwap() {
        instructions.add(new OpCodeInstruction(SWAP, new int[0], "swap"));
    }

    public void addCall(String name) {
        instructions.add(new CallInstruction(name));
    }

    public void addIndirectCall(int idx, String name) {
        instructions.add(new OpCodeInstruction(CALL_INDIRECT|idx, new int[0], "call_indirect " + name));
    }

    public void addJmp(int index, int pc) {
        instructions.add(new JmpInstruction(JMP, pc + index, "jmp " + index));
    }

    public void addToPcMapping(int pc) {
        pcMapping.put(pc, instructions.size());
    }

    public void addReturn(int locals) {
        if (locals == 0)
            instructions.add(new OpCodeInstruction(RET, new int[0], "ret"));
        else
            instructions.add(new OpCodeInstruction(RETN, new int[0], "retn " + locals));
    }

    public void finish() {
        int pc = 0;
        for (var instruction: instructions) {
            if (instruction instanceof JmpInstruction j) {
                j.updateOffset(pc, pcMapping);
            }
            pc += instruction.size;
        }
    }

    public List<Instruction> getInstructions() {
        return instructions;
    }
}
