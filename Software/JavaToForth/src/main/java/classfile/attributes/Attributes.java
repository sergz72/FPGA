package classfile.attributes;

import classfile.ClassFileException;
import classfile.ClassFileInfo;
import classfile.constantpool.ConstantPool;

import java.nio.ByteBuffer;

public class Attributes extends ClassFileInfo<AttributesItem> {
    public Attributes(ConstantPool cp, ByteBuffer bb) throws ClassFileException {
        super(bb, 0, buffer -> {
            try {
                return new ClassFileInfo.CreatorResult<>(new AttributesItem[]{AttributesItem.load(cp, buffer)});
            } catch (ClassFileException e) {
                return new ClassFileInfo.CreatorResult<>(e.getMessage());
            }
        });
    }

    public CodeAttribute getCodeAttribute() throws ClassFileException {
        var ca = items.stream()
                .filter(i -> i instanceof CodeAttribute)
                .map(i -> (CodeAttribute) i)
                .findFirst();
        if (ca.isEmpty())
            throw new ClassFileException("code attribute not found");
        return ca.get();
    }
}
