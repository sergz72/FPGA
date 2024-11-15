package classfile.attributes;

import classfile.ClassFileException;

import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.List;

public class StackMapTableAttribute extends AttributesItem {
    List<IStackMapFrameItem> stackMapFrames;
    public StackMapTableAttribute(ByteBuffer bb, int length) throws ClassFileException {
        super();
        var l = bb.getShort();
        stackMapFrames = new ArrayList<>(l);
        for (var i = 0; i < l; i++) {
            var frameType = bb.get() & 0xFF;
            if (frameType < 64) {
                stackMapFrames.add(new SameTypeStackMapFrameItem(frameType));
            } else if (frameType < 128) {
                stackMapFrames.add(new SameLocals1StackItemStackMapFrameItem(frameType - 64, bb));
            } else if (frameType == 247) {
                stackMapFrames.add(new SameLocals1StackItemStackMapFrameItem(bb.getShort(), bb));
            } else if (frameType >= 248 && frameType <= 250) {
                stackMapFrames.add(new ChopStackMapFrameItem(frameType, bb));
            } else if (frameType == 251) {
                stackMapFrames.add(new SameTypeStackMapFrameItem(bb.getShort()));
            } else if (frameType >= 252 && frameType <= 254) {
                stackMapFrames.add(new AppendStackMapFrameItem(frameType, bb));
            } else if (frameType == 255) {
                stackMapFrames.add(new FullStackMapFrameItem(bb));
            } else
                throw new ClassFileException("Unknown stack map frame type " + frameType);
        }
    }
}
