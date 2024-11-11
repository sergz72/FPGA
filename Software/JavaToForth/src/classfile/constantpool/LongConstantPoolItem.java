package classfile.constantpool;

import java.nio.ByteBuffer;

public class LongConstantPoolItem extends ConstantPoolItem {
    long value;
    public LongConstantPoolItem(ByteBuffer bb) {
        super();
        value = bb.getLong();
    }

    public long getValue() {
        return value;
    }
}
