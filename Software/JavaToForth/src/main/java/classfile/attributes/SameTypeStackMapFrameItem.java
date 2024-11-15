package classfile.attributes;

public class SameTypeStackMapFrameItem implements IStackMapFrameItem {
    int frameType;
    public SameTypeStackMapFrameItem(int frameType) {
        super();
        this.frameType = frameType;
    }
}
