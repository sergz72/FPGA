package classfile.constantpool;

import java.nio.ByteBuffer;

public class InvokeDynamicConstantPoolItem extends ConstantPoolItem {
    int tag, bootstrapMethodAttrIndex, nameAndTypeIndex;
    public InvokeDynamicConstantPoolItem(ByteBuffer bb) {
        super();
        tag = bb.get();
        bootstrapMethodAttrIndex = bb.getShort();
        nameAndTypeIndex = bb.getShort();
    }
}
