package classfile.constantpool;

import classfile.ClassFileException;

import java.nio.ByteBuffer;

public class MethodReferenceConstantPoolItem extends BaseReferenceConstantPoolItem {
    public MethodReferenceConstantPoolItem(ByteBuffer bb) {
        super(bb);
    }

    public String getFullName(ConstantPool cp) throws ClassFileException {
        var nameAndType = cp.get(nameAndTypeIndex);
        if (nameAndType instanceof NameAndTypeConstantPoolItem nt)
            return cp.buildMethodFullName(classIndex, nt.nameIndex, nt.descriptorIndex);
        throw new ClassFileException("wrong nameAndType index for method reference");
    }

    public String getName(ConstantPool cp) throws ClassFileException {
        var nameAndType = cp.get(nameAndTypeIndex);
        if (nameAndType instanceof NameAndTypeConstantPoolItem nt)
            return cp.buildMethodName(nt.nameIndex, nt.descriptorIndex);
        throw new ClassFileException("wrong nameAndType index for method reference");
    }
}
