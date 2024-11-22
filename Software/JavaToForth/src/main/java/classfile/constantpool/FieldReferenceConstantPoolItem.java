package classfile.constantpool;

import classfile.ClassFileException;

import java.nio.ByteBuffer;

public class FieldReferenceConstantPoolItem extends BaseReferenceConstantPoolItem {
    public FieldReferenceConstantPoolItem(ByteBuffer bb) {
        super(bb);
    }

    public String getFullName(ConstantPool cp) throws ClassFileException {
        var nameAndType = cp.get(nameAndTypeIndex);
        if (nameAndType instanceof NameAndTypeConstantPoolItem nt)
            return cp.buildFieldName(classIndex, nt.nameIndex);
        throw new ClassFileException("wrong nameAndType index for field reference");
    }

    public String getName(ConstantPool cp) throws ClassFileException {
        var nameAndType = cp.get(nameAndTypeIndex);
        if (nameAndType instanceof NameAndTypeConstantPoolItem nt)
            return cp.getUtf8Constant(nt.nameIndex);
        throw new ClassFileException("wrong nameAndType index for field reference");
    }

    public boolean isLong(ConstantPool cp) throws ClassFileException {
        var type = cp.getType(nameAndTypeIndex);
        return type.equals("J") || type.equals("D"); // long or double
    }
}
