package translator.instructions;

public abstract class Instruction {
    protected String requiredLabel;
    protected int size;
    protected String comment;
    protected int[] code;
    protected Instruction(String requiredLabel, int size, String comment) {
        this.requiredLabel = requiredLabel;
        this.size = size;
        this.comment = comment;
        code = new int[size];
    }
    public String getRequiredLabel() { return requiredLabel; }
    public int getSize() { return size; }
    public void buildCode(int labelAddress, int pc) {}
}
