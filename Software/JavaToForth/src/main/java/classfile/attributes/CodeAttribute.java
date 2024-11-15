package classfile.attributes;

import classfile.ClassFileException;
import classfile.constantpool.ConstantPool;

import java.nio.ByteBuffer;
import java.util.stream.IntStream;

public class CodeAttribute extends AttributesItem {
    int maxStack, maxlocals;
    byte[] code;
    ExceptionTableItem[] exceptionTable;
    Attributes attributes;
    public CodeAttribute(ConstantPool cp, ByteBuffer bb, int length) throws ClassFileException {
        maxStack = bb.getShort();
        maxlocals = bb.getShort();
        var codelength = bb.getInt();
        code = new byte[codelength];
        bb.get(code);
        var exceptionTableLength = bb.getShort();
        exceptionTable = IntStream.range(0, exceptionTableLength)
                .mapToObj(_ -> new ExceptionTableItem(bb))
                .toArray(ExceptionTableItem[]::new);
        attributes = new Attributes(cp, bb);
    }

    public byte[] getCode() {
        return code;
    }

    public int getNumberOfLocals() {
        return maxlocals;
    }
}
