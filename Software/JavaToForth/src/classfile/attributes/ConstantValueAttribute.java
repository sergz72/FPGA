package classfile.attributes;

import java.nio.ByteBuffer;

public class ConstantValueAttribute extends AttributesItem {
    int constantValueIndex;
    public ConstantValueAttribute(ByteBuffer bb, int length) {
        constantValueIndex = bb.getShort();
    }
}
