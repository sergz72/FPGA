package classfile.attributes;

import java.nio.ByteBuffer;

public class SignatureAttribute extends AttributesItem {
    int signatureIndex;
    public SignatureAttribute(ByteBuffer bb, int length) {
        signatureIndex = bb.getShort();
    }
}
