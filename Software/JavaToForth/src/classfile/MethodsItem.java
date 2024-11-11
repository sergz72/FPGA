package classfile;

import classfile.attributes.Attributes;
import classfile.constantpool.ConstantPool;

import java.nio.ByteBuffer;

public class MethodsItem {
    int accessFlags;
    String name;
    Attributes attributes;
    public MethodsItem(short accessFlags, String name, Attributes attributes) {
        this.accessFlags = accessFlags;
        this.name = name;
        this.attributes = attributes;
    }

    static MethodsItem load(int thisClass, ConstantPool cp, ByteBuffer bb) throws ClassFileException {
        var accessFlags = bb.getShort();
        var name = cp.buildMethodName(thisClass, bb.getShort(), bb.getShort());
        var attributes = new Attributes(cp, bb);
        return new MethodsItem(accessFlags, name, attributes);
    }

    public byte[] getCode() throws ClassFileException {
        var codeAttribute = attributes.getCodeAttribute();
        return codeAttribute.getCode();
    }

    public int getNumberOfLocals() throws ClassFileException {
        var codeAttribute = attributes.getCodeAttribute();
        return codeAttribute.getNumberOfLocals();
    }

    public boolean isNative() {
        return (accessFlags & 0x100) != 0;
    }
}
