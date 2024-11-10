package classfile.attributes;

import java.nio.ByteBuffer;

public class SameLocals1StackItemStackMapFrameItem implements IStackMapFrameItem {
    int offsetDelta;
    VerificationTypeInfo stack1;
    public SameLocals1StackItemStackMapFrameItem(int offsetDelta, ByteBuffer bb) {
        this.offsetDelta = offsetDelta;
        stack1 = new VerificationTypeInfo(bb);
    }
}
