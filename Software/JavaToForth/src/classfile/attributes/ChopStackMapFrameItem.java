package classfile.attributes;

import java.nio.ByteBuffer;

public class ChopStackMapFrameItem implements IStackMapFrameItem {
    int k, offsetDelta;
    public ChopStackMapFrameItem(int frameType, ByteBuffer bb) {
        k = 251 - frameType;
        offsetDelta = bb.getShort();
    }
}
