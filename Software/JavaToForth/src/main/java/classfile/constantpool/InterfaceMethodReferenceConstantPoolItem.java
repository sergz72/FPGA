package classfile.constantpool;

import java.nio.ByteBuffer;

public class InterfaceMethodReferenceConstantPoolItem extends MethodReferenceConstantPoolItem {
    public InterfaceMethodReferenceConstantPoolItem(ByteBuffer bb) {
        super(bb);
    }
}
