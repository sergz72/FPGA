package classfile.attributes;

import classfile.ClassFileException;
import classfile.constantpool.ConstantPool;

import java.nio.ByteBuffer;

public class SourceFileAttribute extends AttributesItem {
    String fileName;
    public SourceFileAttribute(ByteBuffer bb, ConstantPool cp, int length) throws ClassFileException {
        super();
        fileName = cp.getUtf8Constant(bb.getShort());
    }
}
