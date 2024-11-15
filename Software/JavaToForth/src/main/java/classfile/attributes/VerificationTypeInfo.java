package classfile.attributes;

import java.nio.ByteBuffer;

public class VerificationTypeInfo {
    int tag;
    int indexOrOffset;
    public VerificationTypeInfo(ByteBuffer bb) {
        tag = bb.get();
        if (tag >= 7)
            indexOrOffset = bb.getShort();
    }
}
