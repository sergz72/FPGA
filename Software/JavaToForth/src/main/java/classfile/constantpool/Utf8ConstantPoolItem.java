package classfile.constantpool;

import java.nio.ByteBuffer;

public class Utf8ConstantPoolItem extends ConstantPoolItem {
    String value;
    public Utf8ConstantPoolItem(ByteBuffer bb) {
        super();
        var length = bb.getShort();
        var bytes = new byte[length];
        bb.get(bytes);
        value = new String(bytes);
    }
}
