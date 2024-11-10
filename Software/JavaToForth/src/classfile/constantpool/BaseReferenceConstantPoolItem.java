package classfile.constantpool;

import java.nio.ByteBuffer;

public class BaseReferenceConstantPoolItem extends ConstantPoolItem {
    int classIndex, nameAndTypeIndex;
    public BaseReferenceConstantPoolItem(ByteBuffer bb) {
        super();
        classIndex = bb.getShort();
        nameAndTypeIndex = bb.getShort();
    }
}