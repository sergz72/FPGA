package classfile.attributes;

import java.nio.ByteBuffer;

public class ExceptionTableItem {
    int startPc, endPc, handlerPc, catchType;
    ExceptionTableItem(ByteBuffer bb) {
        startPc = bb.getShort();
        endPc = bb.getShort();
        handlerPc = bb.getShort();
        catchType = bb.getShort();
    }
}
