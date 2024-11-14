package classfile.attributes;

import classfile.ClassFileException;
import classfile.constantpool.ConstantPool;

import java.nio.ByteBuffer;

public class AttributesItem {
    static AttributesItem load(ConstantPool cp, ByteBuffer bb) throws ClassFileException {
        var nameIndex = bb.getShort();
        var length = bb.getInt();
        var name = cp.getUtf8Constant(nameIndex);
        return switch (name) {
            case "Code" -> new CodeAttribute(cp, bb, length);
            case "LineNumberTable" -> new LineNumberTableAttribute(bb, length);
            case "StackMapTable" -> new StackMapTableAttribute(bb, length);
            case "SourceFile" -> new SourceFileAttribute(bb, cp, length);
            case "ConstantValue" -> new ConstantValueAttribute(bb, length);
            default -> throw new ClassFileException("Unknown attribute name: " + name);
        };
    }
}
