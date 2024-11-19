package classfile;

import classfile.constantpool.ConstantPool;

import java.nio.ByteBuffer;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

public final class MethodsOrFields extends ClassFileInfo<MethodOrField> {
    Map<String, MethodOrField> map;

    public MethodsOrFields(int thisClass, ConstantPool cp, ByteBuffer bb) throws ClassFileException {
        super(bb, 0, buffer -> {
            try {
                return new ClassFileInfo.CreatorResult<>(new MethodOrField[]{MethodOrField.load(cp, buffer)});
            } catch (ClassFileException e) {
                return new ClassFileInfo.CreatorResult<>(e.getMessage());
            }
        });
        var className = cp.getClassName(thisClass);
        map = this.items.stream().collect(Collectors.toMap(i -> className + "." + i.name, i -> i));
    }

    public boolean hasMethod(String name) {
        return items.stream().anyMatch(i -> i.name.equals(name));
    }

    public List<String> getList() {
        return items.stream()
                .filter(m -> !m.isStatic() && !m.name.equals("<init>()V") && !m.name.equals("<clinit>()V"))
                .map(m -> m.name)
                .collect(Collectors.toList());
    }

    public int getSize() {
        return map.values().stream().mapToInt(f -> f.getSize()).sum();
    }

    public MethodOrField get(String name) {
        return map.get(name);
    }
}
