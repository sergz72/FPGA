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

    public ConstantPoolItem get(int index) {
        index -= 1;
        return this.items.get(index);
    }

    public String getUtf8Constant(int nameIndex) throws ClassFileException {
        var item = get(nameIndex);
        if (item instanceof Utf8ConstantPoolItem ui)
            return ui.value;
        else
            throw new ClassFileException("Constant pool item " + nameIndex + " is not an Utf8ConstantPoolItem");
    }

    public String getClassName(int index) throws ClassFileException {
        var item = get(index);
        if (item instanceof ClassConstantPoolItem c)
            return getUtf8Constant(c.nameIndex);
        else
            throw new ClassFileException("Constant pool item " + index + " is not a ClassConstantPoolItem");
    }

    public String buildMethodFullName(int classIndex, int nameIndex, int descriptorIndex) throws ClassFileException {
        return getClassName(classIndex) + "." + getUtf8Constant(nameIndex) + getUtf8Constant(descriptorIndex);
    }

    public String buildMethodName(int nameIndex, int descriptorIndex) throws ClassFileException {
        return getUtf8Constant(nameIndex) + getUtf8Constant(descriptorIndex);
    }

    public String buildFieldName(int classIndex, int nameIndex) throws ClassFileException {
        return getClassName(classIndex) + "." + getUtf8Constant(nameIndex);
    }

    public boolean isLongField(int index) throws ClassFileException {
        if (get(index) instanceof FieldReferenceConstantPoolItem fr)
            return fr.isLong(this);
        throw new ClassFileException("Constant pool item " + index + " is not a FieldReferenceConstantPoolItem");
    }

    public String getType(int nameAndTypeIndex) throws ClassFileException {
        if (get(nameAndTypeIndex) instanceof NameAndTypeConstantPoolItem nt) {
            return getUtf8Constant(nt.descriptorIndex);
        }
        throw new ClassFileException("Constant pool item " + nameAndTypeIndex + " is not a NameAndTypeConstantPoolItem");
    }
}
