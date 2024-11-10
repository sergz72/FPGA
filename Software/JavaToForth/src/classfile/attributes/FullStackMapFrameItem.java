package classfile.attributes;

import java.nio.ByteBuffer;
import java.util.stream.IntStream;

public class FullStackMapFrameItem implements IStackMapFrameItem {
    int offsetDelta;
    VerificationTypeInfo[] locals;
    VerificationTypeInfo[] stack;
    public FullStackMapFrameItem(ByteBuffer bb) {
        offsetDelta = bb.getShort();
        var l = bb.getShort();
        locals = IntStream.range(0, l).mapToObj(_ -> new VerificationTypeInfo(bb)).toArray(VerificationTypeInfo[]::new);
        l = bb.getShort();
        stack = IntStream.range(0, l).mapToObj(_ -> new VerificationTypeInfo(bb)).toArray(VerificationTypeInfo[]::new);
    }
}
