package classfile.constantpool;

import classfile.ClassFileException;

import java.nio.ByteBuffer;

public class ConstantPoolItem {
    static ConstantPoolItem load(ByteBuffer bb) throws ClassFileException {
        var tag = bb.get();
        return switch (tag) {
            case 1 -> new Utf8ConstantPoolItem(bb);
            case 3 -> new IntConstantPoolItem(bb);
            case 4 -> new FloatConstantPoolItem(bb);
            case 5 -> new LongConstantPoolItem(bb);
            case 6 -> new DoubleConstantPoolItem(bb);
            case 7 -> new ClassConstantPoolItem(bb);
            case 8 -> new StringConstantPoolItem(bb);
            case 9 -> new FieldReferenceConstantPoolItem(bb);
            case 10 -> new MethodReferenceConstantPoolItem(bb);
            case 11 -> new InterfaceMethodReferenceConstantPoolItem(bb);
            case 12 -> new NameAndTypeConstantPoolItem(bb);
            case 15 -> new MethodHandleConstantPoolItem(bb);
            case 16 -> new MethodTypeConstantPoolItem(bb);
            case 18 -> new InvokeDynamicConstantPoolItem(bb);
            default -> throw new ClassFileException("Unknown constant pool tag: " + tag);
        };
    }
}
