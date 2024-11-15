package classfile.constantpool;

import java.nio.ByteBuffer;

public class ClassConstantPoolItem extends ConstantPoolItem {
    int nameIndex;
    public ClassConstantPoolItem(ByteBuffer bb) {
        super();
        nameIndex = bb.getShort();
    }
}
