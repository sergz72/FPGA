package translator.instructions;

public abstract class Instruction {
    protected final String requiredLabel;
    protected String comment;
    protected int[] code;
    private final Integer bytecodePc;
    protected Instruction(String requiredLabel, int size, Integer bytecodePc, String comment) {
        this.requiredLabel = requiredLabel;
        this.comment = comment;
        this.bytecodePc = bytecodePc;
        code = new int[size];
    }
    public String getRequiredLabel() { return requiredLabel; }
    public int getSize() { return code.length; }
    public void buildCode(int labelAddress, int pc) {}

    public String[] toText(String label, int pc, boolean w32) {
        var result = new String[code.length];
        for (int i = 0; i < code.length; i++) {
            if (bytecodePc != null) {
                var format = w32 ? "%08X // %08X %5d %s" : "%04X // %08X %5d %s";
                result[i] = String.format(format, code[i], pc++, bytecodePc,
                        i == 0 ? buildComment(comment, label) : "");
            }
            else {
                var format = w32 ? "%08X // %08X       %s" : "%04X // %08X       %s";
                result[i] = String.format(format, code[i], pc++, i == 0 ? buildComment(comment, label) : "");
            }
        }
        return result;
    }

    private static String buildComment(String comment, String label) {
        return comment + (label.isEmpty() ? "" : " ; " + label);
    }

    public boolean isPush() {
        var opCode = code[0] >> 8;
        return opCode == InstructionGenerator.PUSH || opCode == InstructionGenerator.PUSH_LONG ||
                opCode == InstructionGenerator.LOCAL_GET || opCode == InstructionGenerator.BPUSH ||
                opCode == InstructionGenerator.SPUSH;
    }

    public boolean isSetLocal(int i) {
        var opCode = code[0] >> 8;
        int n = getParameter();
        return opCode == InstructionGenerator.LOCAL_SET && n == i;
    }

    public void modifyOpCode(int opCode, String comment) {
        int parameter = getParameter();
        code[0] = (opCode << 8) | parameter;
        this.comment = comment;
    }

    public boolean isGetLocal() {
        var opCode = code[0] >> 8;
        return opCode == InstructionGenerator.LOCAL_GET;
    }

    public int getParameter() {
        return code[0] & 0xFF;
    }
}
