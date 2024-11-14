package classfile;

import classfile.constantpool.ConstantPool;

import java.nio.ByteBuffer;
import java.util.Map;
import java.util.stream.Collectors;

public final class MethodsOrFields extends ClassFileInfo<MethodOrField> {
    Map<String, MethodOrField> map;

    public MethodsOrFields(int thisClass, ConstantPool cp, ByteBuffer bb) throws ClassFileException {
        super(bb, 0, buffer -> {
            try {
                return new ClassFileInfo.CreatorResult<>(new MethodOrField[]{MethodOrField.load(thisClass, cp, buffer)});
            } catch (ClassFileException e) {
                return new ClassFileInfo.CreatorResult<>(e.getMessage());
            }
        });
        map = this.items.stream().collect(Collectors.toMap(i -> i.name, i -> i));
    }
}
