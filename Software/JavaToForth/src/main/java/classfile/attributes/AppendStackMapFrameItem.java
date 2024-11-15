package classfile.attributes;

import java.nio.ByteBuffer;
import java.util.stream.IntStream;

public class AppendStackMapFrameItem implements IStackMapFrameItem {
    int k, offsetDelta;
    VerificationTypeInfo[] locals;
    public AppendStackMapFrameItem(int frameType, ByteBuffer bb) {
        k = frameType - 251;
        offsetDelta = bb.getShort();
        locals = IntStream.range(0, k).mapToObj(_ -> new VerificationTypeInfo(bb)).toArray(VerificationTypeInfo[]::new);
    }
}
