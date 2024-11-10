package classfile.constantpool;

import java.nio.ByteBuffer;

public class StringConstantPoolItem extends ConstantPoolItem {
    int stringIndex;
    public StringConstantPoolItem(ByteBuffer bb) {
        super();
        stringIndex = bb.getShort();
    }
}
