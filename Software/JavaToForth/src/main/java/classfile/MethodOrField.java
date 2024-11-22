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
        this.name = name + descriptor;
        this.attributes = attributes;
        this.descriptor = descriptor;
    }

    static MethodOrField load(ConstantPool cp, ByteBuffer bb) throws ClassFileException {
        var accessFlags = bb.getShort();
        var name = cp.getUtf8Constant(bb.getShort());
        var descriptor = cp.getUtf8Constant(bb.getShort());
        var attributes = new Attributes(cp, bb);
        return new MethodOrField(accessFlags, name, descriptor, attributes);
    }

    public byte[] getCode() throws ClassFileException {
        var codeAttribute = attributes.getCodeAttribute();
        return codeAttribute.getCode();
    }

    public int getNumberOfLocals() throws ClassFileException {
        var codeAttribute = attributes.getCodeAttribute();
        if (codeAttribute == null)
            return -1;
        return codeAttribute.getNumberOfLocals();
    }

    public int getNumberOfParameters() throws ClassFileException {
        return getNumberOfParameters(descriptor);
    }

    public static int getNumberOfParameters(String descriptor) throws ClassFileException {
        var idx = descriptor.indexOf('(');
        var idx2 = descriptor.indexOf(')');
        if (idx < 0 || idx2 < 0 || idx > idx2)
            throw new ClassFileException("Invalid method descriptor" + descriptor);
        int count = 0;

        idx++;

        while (idx < idx2) {
            var c = descriptor.charAt(idx);
            switch (c) {
                case 'L':
                    idx = descriptor.indexOf(';', idx + 1);
                    if (idx <= 0)
                        throw new ClassFileException("Invalid method descriptor" + descriptor);
                    break;
                case 'C':
                case 'I':
                case 'J':
                case 'Z':
                case '[': // array
                    break;
                default:
                    throw new ClassFileException(String.format("Unsupported char in method descriptor: %c %s", c, descriptor));
            }
            if (c != '[')
                count++;
            idx++;
        }

        return count;
    }

    public boolean isNative() {
        return (accessFlags & 0x100) != 0;
    }

    public boolean isStatic() {
        return (accessFlags & 8) != 0;
    }

    public boolean isVarargs() {
        return (accessFlags & 0x80) != 0;
    }

    public int getSize() {
        // long or double
        return descriptor.equals("L") || descriptor.equals("D") ? 2 : 1;
    }
}
