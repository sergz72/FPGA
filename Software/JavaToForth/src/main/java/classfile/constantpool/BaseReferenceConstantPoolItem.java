package classfile.constantpool;

import classfile.ClassFileException;

import java.nio.ByteBuffer;

public class BaseReferenceConstantPoolItem extends ConstantPoolItem {
    int classIndex, nameAndTypeIndex;
    public BaseReferenceConstantPoolItem(ByteBuffer bb) {
        super();
        classIndex = bb.getShort();
        nameAndTypeIndex = bb.getShort();
    }

    public String getClassName(ConstantPool constantPoolInfo) throws ClassFileException {
        return constantPoolInfo.getClassName(classIndex);
    }
}