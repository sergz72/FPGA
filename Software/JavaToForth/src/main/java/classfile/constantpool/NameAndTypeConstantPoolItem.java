package classfile.constantpool;

import java.nio.ByteBuffer;

public class NameAndTypeConstantPoolItem extends ConstantPoolItem {
    int nameIndex, descriptorIndex;
    public NameAndTypeConstantPoolItem(ByteBuffer bb) {
        super();
        nameIndex = bb.getShort();
        descriptorIndex = bb.getShort();
    }
}
