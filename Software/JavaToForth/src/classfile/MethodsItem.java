package classfile;

import classfile.attributes.Attributes;
import classfile.constantpool.ConstantPool;

import java.nio.ByteBuffer;

public class MethodsItem {
    int accessFlags, descriptorIndex;
    String name;
    Attributes attributes;
    public MethodsItem(short accessFlags, String name, short descriptorIndex, Attributes attributes) {
        this.accessFlags = accessFlags;
        this.name = name;
        this.descriptorIndex = descriptorIndex;
        this.attributes = attributes;
    }

    static MethodsItem load(ConstantPool cp, ByteBuffer bb) throws ClassFileException {
        var accessFlags = bb.getShort();
        var name = cp.getUtf8Constant(bb.getShort());
        var descriptorIndex = bb.getShort();
        var attributes = new Attributes(cp, bb);
        return new MethodsItem(accessFlags, name, descriptorIndex, attributes);
    }

    public byte[] getCode() throws ClassFileException {
        var codeAttribute = attributes.getCodeAttribute();
        return codeAttribute.getCode();
    }
}
