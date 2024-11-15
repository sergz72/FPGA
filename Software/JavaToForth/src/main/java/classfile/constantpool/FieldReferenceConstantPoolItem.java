package classfile.constantpool;

import classfile.ClassFileException;

import java.nio.ByteBuffer;

public class FieldReferenceConstantPoolItem extends BaseReferenceConstantPoolItem {
    public FieldReferenceConstantPoolItem(ByteBuffer bb) {
        super(bb);
    }

    public String getName(ConstantPool cp) throws ClassFileException {
        var nameAndType = cp.get(nameAndTypeIndex);
        if (nameAndType instanceof NameAndTypeConstantPoolItem nt)
            return cp.buildFieldName(classIndex, nt.nameIndex);
        throw new ClassFileException("wrong nameAndType index for field reference");
    }
}
