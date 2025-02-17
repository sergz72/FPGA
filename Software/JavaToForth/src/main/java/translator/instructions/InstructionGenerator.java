package translator.instructions;

import java.util.*;

public class InstructionGenerator {
    static final int PUSH = 0;
    static final int PUSH_LONG = 1;
    private static final int DUP = 2;
    private static final int SET = 3;
    private static final int SET_LONG = 4;
    static final int JMP = 5;
    private static final int GET = 6;
    private static final int GET_LONG = 7;
    static final int CALL = 8;
    private static final int CALL_INDIRECT = 9;
    private static final int RET = 10;
    private static final int RETN = 11;
    private static final int HLT = 12;
    private static final int WFI = 13;
    private static final int NEG = 14;
    private static final int INC = 15;
    private static final int RETI = 16;
    private static final int DROP = 17;
    private static final int DROP2 = 18;
    private static final int SWAP = 19;
    private static final int ROT = 20;
    private static final int OVER = 21;
    static final int LOCAL_GET = 22;
    static final int LOCAL_SET = 23;
    private static final int LOCALS = 24;
    private static final int NOP = 25;
    private static final int GET_DATA_STACK_POINTER = 26;
    private static final int IFCMP = 27;
    private static final int IF = 28;
    private static final int ALU_OP = 29;
    private static final int ARRAYP = 30;
    private static final int ARRAYP2 = 31;
    static final int BPUSH = 32;
    static final int SPUSH = 33;
    private static final int GETN = 34;
    private static final int JMP_INDIRECT = 35;
    private static final int DIV = 36;
    private static final int REM = 37;
    private static final int LOCAL_NPSET = 38;

    public static final int ALU_OP_ADD      = 0;
    public static final int ALU_OP_SUB      = 1;
    public static final int ALU_OP_AND      = 2;
    public static final int ALU_OP_OR       = 3;
    public static final int ALU_OP_XOR      = 4;
    public static final int ALU_OP_SHL      = 5;
    public static final int ALU_OP_LLSHR     = 6;
    public static final int ALU_OP_ILSHR     = 7;
    public static final int ALU_OP_ASHR     = 8;
    public static final int ALU_OP_BIT_TEST = 9;
    public static final int ALU_OP_MUL      = 10;
    public static final int ALU_OP_CMP      = 11;

    public static final int IF_LT = 2;
    public static final int IF_GE = 2 + 4;
    public static final int IF_EQ = 1;
    public static final int IF_NE = 1 + 4;
    public static final int IF_GT = 1 + 2 + 4; // not LT & not EQ
    public static final int IF_LE = 1 + 2; // LT | EQ

    public static final int IFCMP_GT = 2;
    public static final int IFCMP_EQ = 1;
    public static final int IFCMP_NE = 1 + 4;
    public static final int IFCMP_LE = 2 + 4;
    public static final int IFCMP_LT = 1 + 2 + 4; // not GT & not EQ
    public static final int IFCMP_GE = 1 + 2; // GT | EQ

    final List<Instruction> instructions;
    // mapping bytecodePc > instruction pc
    final Map<Integer, Integer> pcMapping;
    final boolean dropOptimnization;
    final boolean swapOptimnization;
    final boolean localsOptimnization;

    Integer bytecodePc;
    int ipc;

    public InstructionGenerator(Integer bytecodePc, boolean dropOptimization, boolean swapOptimization,
                                boolean localsOptimization) {
        instructions = new ArrayList<>();
        pcMapping = new HashMap<>();
        this.bytecodePc = bytecodePc;
        ipc = 0;
        this.dropOptimnization = dropOptimization;
        this.swapOptimnization = swapOptimization;
        this.localsOptimnization = localsOptimization;
    }

    public InstructionGenerator(Integer bytecodePc) {
        this(bytecodePc, false, false, false);
    }

    private void addInstruction(Instruction i) {
        instructions.add(i);
        ipc += i.getSize();
    }

    public void addSPush(int value, String comment)
    {
        addInstruction(new OpCodeInstruction(bytecodePc, SPUSH, 0, new int[]{value & 0xFFFF},
                            String.format("spush %d %x (%s)", value, value, comment)));
    }

    public void addBPush(int value, String comment)
    {
        addInstruction(new OpCodeInstruction(bytecodePc, BPUSH, value, new int[0],
                            String.format("bpush %d %x (%s)", value, value, comment)));
    }

    public void addPush(int value, String comment)
    {
        addInstruction(new OpCodeInstruction(bytecodePc, PUSH, 0, new int[]{value & 0xFFFF, value >> 16},
                            String.format("push %d %x (%s)", value, value, comment)));
    }

    public void addPushLong(long value) {
        int v1 = (int)(value & 0xFFFF);
        int v2 = (int)(value >> 16);
        int v3 = (int)(value >> 32);
        int v4 = (int)(value >> 48);
        addInstruction(new OpCodeInstruction(bytecodePc, PUSH_LONG, 0, new int[]{v1, v2, v3, v4},
                String.format("push_long %d %x", value, value)));
    }

    public void addGetn(int n, String comment)
    {
        addInstruction(new OpCodeInstruction(bytecodePc, GETN, n, new int[0], comment));
    }

    public void addGet(String comment)
    {
        addInstruction(new OpCodeInstruction(bytecodePc, GET, 0, new int[0], comment));
    }

    public void addGetLong()
    {
        addInstruction(new OpCodeInstruction(bytecodePc, GET_LONG, 0, new int[0], "lget"));
    }

    public void addSet()
    {
        addInstruction(new OpCodeInstruction(bytecodePc, SET, 0, new int[0], "iset"));
    }

    public void addSetLong()
    {
        addInstruction(new OpCodeInstruction(bytecodePc, SET_LONG, 0, new int[0], "lset"));
    }

    public void addDup()
    {
        addInstruction(new OpCodeInstruction(bytecodePc, DUP, 0, new int[0], "dup"));
    }

    public void addDup2()
    {
        addInstruction(new OpCodeInstruction(bytecodePc, OVER, 0, new int[]{OVER}, "dup2(over over)"));
    }

    public void add2Rot()
    {
        addInstruction(new OpCodeInstruction(bytecodePc, ROT, 0, new int[0], "rot"));
        addInstruction(new OpCodeInstruction(bytecodePc, ROT, 0, new int[0], "rot"));
    }

    public void addGetLocal(int i) {
        addInstruction(new OpCodeInstruction(bytecodePc, LOCAL_GET, i, new int[0], String.format("local_get %d", i)));
    }

    public void addSetLocal(int i) {
        addInstruction(new OpCodeInstruction(bytecodePc, LOCAL_SET, i, new int[0], String.format("local_set %d", i)));
    }

    public void addAluOp(int aluOp, String comment) {
        addInstruction(new OpCodeInstruction(bytecodePc, ALU_OP, aluOp, new int[0], comment));
    }

    public void addIfcmp(int code, String comment, int index, int pc) {
        var to = pc + index;
        addInstruction(new JmpInstruction(bytecodePc, IFCMP, code, pc + index, comment + " " + to));
    }

    public void addIfcmp(int code, String comment, int offset) {
        addInstruction(new JmpOffsetInstruction(bytecodePc, IFCMP, code, offset, comment + " " + offset));
    }

    public void addIf(int code, String comment, int index, int pc) {
        var to = pc + index;
        addInstruction(new JmpInstruction(bytecodePc, IF, code, to, comment + " " + to));
    }

    public void addInc(int index, int value) {
        addInstruction(new OpCodeInstruction(bytecodePc, INC, index, new int[]{value&0xFFFF}, String.format("inc %d %d", index, value)));
    }

    public void addNeg() {
        addInstruction(new OpCodeInstruction(bytecodePc, NEG, 0, new int[0], "neg"));
    }

    public void addNop() {
        addInstruction(new OpCodeInstruction(bytecodePc, NOP, 0, new int[0], "nop"));
    }

    public void addDrop() {
        var i1 = instructions.getLast();
        if (dropOptimnization && i1.isPush()) {
            instructions.removeLast();
            System.out.println("    Optimizing push drop at " + bytecodePc);
        }
        else
            addInstruction(new OpCodeInstruction(bytecodePc, DROP, 0, new int[0], "drop"));
    }

    public void addDrop2() {
        addInstruction(new OpCodeInstruction(bytecodePc, DROP2, 0, new int[0], "drop2"));
    }

    public void addSwap() {
        if (!swapOptimnization || !canReorderToAvoidSwap())
            addInstruction(new OpCodeInstruction(bytecodePc, SWAP, 0, new int[0], "swap"));
    }

    private boolean canReorderToAvoidSwap() {
        var i1 = instructions.getLast();
        var i2 = instructions.get(instructions.size() - 2);
        var canReorder = i1.isPush() && i2.isPush();
        if (canReorder) {
            instructions.set(instructions.size() - 2, i1);
            instructions.set(instructions.size() - 1, i2);
            System.out.println("    Reordering to avoid swap at " + bytecodePc);
        }
        return canReorder;
    }

    public void addCall(String name) {
        addInstruction(new CallInstruction(bytecodePc, name));
    }

    public void addIndirectCall(int idx, String name) {
        addInstruction(new OpCodeInstruction(bytecodePc, CALL_INDIRECT, idx, new int[0], "call_indirect " + name));
    }

    public void addJmp(int index, int pc) {
        var to = pc + index;
        addInstruction(new JmpInstruction(bytecodePc, JMP, 0, to, "jmp " + to));
    }

    public void setCurrentBytecodePc(int pc) {
        bytecodePc = pc;
        pcMapping.put(pc, ipc);
    }

    public void addReturn(int locals) {
        if (locals == 0)
            addInstruction(new OpCodeInstruction(bytecodePc, RET, 0, new int[0], "ret"));
        else
            addInstruction(new OpCodeInstruction(bytecodePc, RETN, locals, new int[0], "retn " + locals));
    }

    public void addReti(int locals) {
        addInstruction(new OpCodeInstruction(bytecodePc, RETI, locals, new int[0], "reti " + locals));
    }

    public void finish() {
        if (localsOptimnization)
            optimizeLocalSetLocalGet();
        int pc = 0;
        for (var instruction: instructions) {
            if (instruction instanceof JmpInstruction j) {
                j.updateOffset(pc, pcMapping);
            }
            pc += instruction.getSize();
        }
    }

    private void optimizeLocalSetLocalGet() {
        if (instructions.size() < 2)
            return;
        var pc = instructions.getFirst().getSize();
        for (int i = 1; i < instructions.size();) {
            var i1 = instructions.get(i-1);
            var i2 = instructions.get(i);
            if (i2.isGetLocal() && i1.isSetLocal(i2.getParameter())) {
                if (remove(i, pc)) {
                    System.out.println("    local_set local_get -> local_npset at " + pc);
                    i1.modifyOpCode(LOCAL_NPSET, String.format("local_npset %d", i2.getParameter()));
                } else {
                    System.out.println("    local_set local_get -> not optimizing due to existing references at " + pc);
                    pc += i2.getSize();
                    i++;
                }
            }
            else {
                pc += i2.getSize();
                i++;
            }
        }
    }

    private boolean remove(int index, int pc) {
        var bytecodePcOpt = pcMapping.entrySet().stream().filter(e -> e.getValue() == pc).findFirst();
        var result = bytecodePcOpt
                .map(mapping -> !referencesExists(mapping.getKey()))
                .orElse(true);
        if (result) {
            instructions.remove(index);
            updatePcMapping(pc);
        }
        return result;
    }

    private void updatePcMapping(int pc) {
        for (var m: pcMapping.entrySet()) {
            var v = m.getValue();
            if (v >= pc)
                pcMapping.put(m.getKey(), v - 1);
        }
    }

    private boolean referencesExists(int index) {
        for (var i: instructions) {
            if (i instanceof JmpInstruction j && j.getTo() == index)
                return true;
        }
        return false;
    }

    public List<Instruction> getInstructions() {
        return instructions;
    }

    public void addArrayp() {
        addInstruction(new OpCodeInstruction(bytecodePc, ARRAYP, 0, new int[0], "arrayp"));
    }

    public void addArrayp2() {
        addInstruction(new OpCodeInstruction(bytecodePc, ARRAYP2, 0, new int[0], "arrayp"));
    }

    public void addDiv(String comment) {
        addInstruction(new OpCodeInstruction(bytecodePc, DIV, 0, new int[0], comment));
    }

    public void addRem(String comment) {
        addInstruction(new OpCodeInstruction(bytecodePc, REM, 0, new int[0], comment));
    }

    public void addOpcodes(int[] code, String comment) {
        if (code.length == 1 && code[0] == InstructionGenerator.DROP << 8)
            addDrop();
        else
            addInstruction(new InlineInstruction(bytecodePc, code, comment));
    }

    public void addHlt() {
        addInstruction(new OpCodeInstruction(bytecodePc, HLT, 0, new int[0], "hlt"));
    }

    public void addJmpToLabel(String name) {
        addInstruction(new JmpLabelInstruction(bytecodePc, name));
    }

    public void addPushLabel(String name) {
        addInstruction(new PushLabelInstruction(bytecodePc, name));
    }

    public void addLocals(int localsCount) {
        addInstruction(new OpCodeInstruction(bytecodePc, LOCALS, localsCount, new int[0], "locals " + localsCount));
    }

    public void addIndirectJmp() {
        addInstruction(new OpCodeInstruction(bytecodePc, JMP_INDIRECT, 0, new int[0], "ijmp"));
    }
}
