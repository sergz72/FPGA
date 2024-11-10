package classfile.constantpool;

import classfile.ClassFileException;
import classfile.ClassFileInfo;

import java.nio.ByteBuffer;

public class ConstantPool extends ClassFileInfo<ConstantPoolItem> {
    public ConstantPool(ByteBuffer bb) throws ClassFileException {
        super(bb, 1, buffer -> {
            try {
                return new CreatorResult<>(ConstantPoolItem.load(buffer));
            } catch (ClassFileException e) {
                return new CreatorResult<>(e.getMessage());
            }
        });
    }

    public String getUtf8Constant(int nameIndex) throws ClassFileException {
        nameIndex -= 1;
        var item = this.items.get(nameIndex);
        if (item instanceof Utf8ConstantPoolItem ui)
            return ui.value;
        else
            throw new ClassFileException("Constant pool item " + nameIndex + " is not an Utf8ConstantPoolItem");
    }

    public String getClassName(int index) throws ClassFileException {
        index -= 1;
        var item = this.items.get(index);
        if (item instanceof ClassConstantPoolItem c)
            return getUtf8Constant(c.nameIndex);
        else
            throw new ClassFileException("Constant pool item " + index + " is not a ClassConstantPoolItem");
    }
}
