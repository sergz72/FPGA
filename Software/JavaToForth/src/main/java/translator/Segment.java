package translator;

import translator.instructions.Instruction;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public final class Segment {
    private String name;
    private int nextAddress;
    private final List<Instruction> instructions;

    Segment(String name, int address) {
        this.name = name;
        nextAddress = address;
        instructions = new ArrayList<>();
    }

    int addInstruction(Instruction i) {
        this.instructions.add(i);
        var address = nextAddress;
        nextAddress += i.getSize();
        return address;
    }

    int allocate(int size) {
        var address = nextAddress;
        nextAddress += size;
        return address;
    }

    public List<Instruction> getInstructions() {
        return instructions;
    }
}
