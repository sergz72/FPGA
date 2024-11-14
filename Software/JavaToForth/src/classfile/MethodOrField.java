package classfile;

import classfile.attributes.Attributes;
import classfile.constantpool.ConstantPool;

import java.nio.ByteBuffer;
import java.util.Arrays;

public class MethodOrField {
    int accessFlags;
    String name, descriptor;
    Attributes attributes;
    public MethodOrField(short accessFlags, String name, String descriptor, Attributes attributes) {
        this.accessFlags = accessFlags;
        this.name = name;
        this.attributes = attributes;
        this.descriptor = descriptor;
    }

    static MethodOrField load(int thisClass, ConstantPool cp, ByteBuffer bb) throws ClassFileException {
        var accessFlags = bb.getShort();
        var n = bb.getShort();
        var descriptor = bb.getShort();
        var descriptorName = cp.getUtf8Constant(descriptor);
        var name = cp.buildMethodName(thisClass, n, descriptor);
        var attributes = new Attributes(cp, bb);
        return new MethodOrField(accessFlags, name, descriptorName, attributes);
    }

    public byte[] getCode() throws ClassFileException {
        var codeAttribute = attributes.getCodeAttribute();
        return codeAttribute.getCode();
    }

    public int getNumberOfLocals() throws ClassFileException {
        var codeAttribute = attributes.getCodeAttribute();
        return codeAttribute.getNumberOfLocals();
    }

    public int getNumberOfParameters() throws ClassFileException {
        var idx1 = descriptor.indexOf('(');
        var idx2 = descriptor.indexOf(')');
        if (idx1 < 0 || idx2 < 0)
            throw new ClassFileException("Invalid method descriptor" + descriptor);
        var count = Arrays.stream(descriptor.substring(idx1 + 1, idx2)
                .split(";"))
                .filter(p -> !p.isEmpty())
                .count();
        return (int)count;
    }

    public boolean isNative() {
        return (accessFlags & 0x100) != 0;
    }
}
