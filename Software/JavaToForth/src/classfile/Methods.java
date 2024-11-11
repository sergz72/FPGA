package classfile;

import classfile.constantpool.ConstantPool;

import java.nio.ByteBuffer;
import java.util.Map;
import java.util.stream.Collectors;

public final class Methods extends ClassFileInfo<MethodsItem> {
    Map<String, MethodsItem> methods;

    public Methods(int thisClass, ConstantPool cp, ByteBuffer bb) throws ClassFileException {
        super(bb, 0, buffer -> {
            try {
                return new ClassFileInfo.CreatorResult<>(new MethodsItem[]{MethodsItem.load(thisClass, cp, buffer)});
            } catch (ClassFileException e) {
                return new ClassFileInfo.CreatorResult<>(e.getMessage());
            }
        });
        methods = this.items.stream().collect(Collectors.toMap(i -> i.name, i -> i));
    }
}
