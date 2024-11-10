package classfile.constantpool;

import java.nio.ByteBuffer;

public class MethodReferenceConstantPoolItem extends BaseReferenceConstantPoolItem {
    public MethodReferenceConstantPoolItem(ByteBuffer bb) {
        super(bb);
    }
}
