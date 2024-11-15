package classfile.attributes;

import java.nio.ByteBuffer;

public class LineNumberTableItem {
    int startPc;
    int lineNumber;
    public LineNumberTableItem(ByteBuffer bb) {
        startPc = bb.getShort();
        lineNumber = bb.getShort();
    }
}
