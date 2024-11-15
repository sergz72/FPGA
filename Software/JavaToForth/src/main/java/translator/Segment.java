package translator;

import translator.instructions.Instruction;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public final class Segment {
    private String name;
    private int nextAddress, nextAddressFromEnd;
    private final List<Instruction> instructions;

    Segment(String name, int address, int size) {
        this.name = name;
        nextAddress = address;
        nextAddressFromEnd = address + size - 1;
        instructions = new ArrayList<>();
    }

    int addInstruction(Instruction i) {
        this.instructions.add(i);
        var address = nextAddress;
        nextAddress += i.getSize();
        return address;
    }

    int allocate(int size) {
        var address = nextAddressFromEnd;
        nextAddressFromEnd -= size;
        return address;
    }

    void finish() throws TranslatorException {
        if (nextAddress >= nextAddressFromEnd)
            throw new TranslatorException(name + " segment overflow");
    }

    public List<Instruction> getInstructions() {
        return instructions;
    }
}
