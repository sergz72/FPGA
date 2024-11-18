package translator.instructions;

public abstract class Instruction {
    protected final String requiredLabel;
    protected final String comment;
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
}
