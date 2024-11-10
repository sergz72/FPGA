package classfile.constantpool;

import java.nio.ByteBuffer;

public class FloatConstantPoolItem extends ConstantPoolItem {
    float value;
    public FloatConstantPoolItem(ByteBuffer bb) {
        super();
        value = bb.getFloat();
    }
}
