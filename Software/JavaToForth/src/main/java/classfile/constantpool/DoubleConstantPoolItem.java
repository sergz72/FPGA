package classfile.constantpool;

import java.nio.ByteBuffer;

public class DoubleConstantPoolItem extends ConstantPoolItem {
    double value;
    public DoubleConstantPoolItem(ByteBuffer bb) {
        super();
        value = bb.getDouble();
    }
}
