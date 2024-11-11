package translator.instructions;

public class CallInstruction extends Instruction {
    protected CallInstruction(String name) {
        super(name, 3, "call " + name);
    }
}
