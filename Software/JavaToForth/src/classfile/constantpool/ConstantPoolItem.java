package classfile.constantpool;

import classfile.ClassFileException;

import java.nio.ByteBuffer;

public class ConstantPoolItem {
    static ConstantPoolItem[] load(ByteBuffer bb) throws ClassFileException {
        var tag = bb.get();
        return switch (tag) {
            case 1 -> new ConstantPoolItem[]{new Utf8ConstantPoolItem(bb)};
            case 3 -> new ConstantPoolItem[]{new IntConstantPoolItem(bb)};
            case 4 -> new ConstantPoolItem[]{new FloatConstantPoolItem(bb)};
            case 5 -> new ConstantPoolItem[]{new LongConstantPoolItem(bb), null};
            case 6 -> new ConstantPoolItem[]{new DoubleConstantPoolItem(bb), null};
            case 7 -> new ConstantPoolItem[]{new ClassConstantPoolItem(bb)};
            case 8 -> new ConstantPoolItem[]{new StringConstantPoolItem(bb)};
            case 9 -> new ConstantPoolItem[]{new FieldReferenceConstantPoolItem(bb)};
            case 10 -> new ConstantPoolItem[]{new MethodReferenceConstantPoolItem(bb)};
            case 11 -> new ConstantPoolItem[]{new InterfaceMethodReferenceConstantPoolItem(bb)};
            case 12 -> new ConstantPoolItem[]{new NameAndTypeConstantPoolItem(bb)};
            case 15 -> new ConstantPoolItem[]{new MethodHandleConstantPoolItem(bb)};
            case 16 -> new ConstantPoolItem[]{new MethodTypeConstantPoolItem(bb)};
            case 18 -> new ConstantPoolItem[]{new InvokeDynamicConstantPoolItem(bb)};
            default -> throw new ClassFileException("Unknown constant pool tag: " + tag);
        };
    }
}
