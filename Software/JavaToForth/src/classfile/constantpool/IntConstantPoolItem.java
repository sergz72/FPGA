package classfile.constantpool;

import java.nio.ByteBuffer;

public class IntConstantPoolItem extends ConstantPoolItem {
    int value;
    public IntConstantPoolItem(ByteBuffer bb) {
        super();
        value = bb.getInt();
    }

    public int getValue() {
        return value;
    }
}
