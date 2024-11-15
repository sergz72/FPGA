package classfile.constantpool;

import java.nio.ByteBuffer;

public class FieldReferenceConstantPoolItem extends BaseReferenceConstantPoolItem {
    public FieldReferenceConstantPoolItem(ByteBuffer bb) {
        super(bb);
    }
}
