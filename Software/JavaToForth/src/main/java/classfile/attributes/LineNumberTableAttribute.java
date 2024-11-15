package classfile.attributes;

import classfile.constantpool.ConstantPool;

import java.nio.ByteBuffer;
import java.util.stream.IntStream;

public class LineNumberTableAttribute extends AttributesItem {
    LineNumberTableItem[] lineNumberTable;
    public LineNumberTableAttribute(ByteBuffer bb, int length) {
        super();
        var l = bb.getShort();
        lineNumberTable = IntStream.range(0, l)
                .mapToObj(_ -> new LineNumberTableItem(bb))
                .toArray(LineNumberTableItem[]::new);
    }
}
