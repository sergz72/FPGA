package classfile.constantpool;

import java.nio.ByteBuffer;

public class MethodHandleConstantPoolItem extends ConstantPoolItem {
    int referenceKind, referenceIndex;
    public MethodHandleConstantPoolItem(ByteBuffer bb) {
        super();
        referenceKind = bb.get();
        referenceIndex = bb.getShort();
    }
}
