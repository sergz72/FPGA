package classfile.constantpool;

import java.nio.ByteBuffer;

public class MethodTypeConstantPoolItem extends ConstantPoolItem {
    int tag, descriptorIndex;
    public MethodTypeConstantPoolItem(ByteBuffer bb) {
        super();
        tag = bb.get();
        descriptorIndex = bb.getShort();
    }
}
