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
        map = this.items.stream().collect(Collectors.toMap(i -> className + "." + i.nameWithDescriptor, i -> i));
    }

    public boolean hasMethod(String name) {
        return items.stream().anyMatch(i -> i.nameWithDescriptor.equals(name));
    }

    public List<String> getMethodList() {
        return items.stream()
                .filter(m -> !m.isStatic() && !m.nameWithDescriptor.startsWith("<init>") && !m.nameWithDescriptor.equals("<clinit>()V"))
                .map(m -> m.nameWithDescriptor)
                .collect(Collectors.toList());
    }

    public List<FieldInfo> getFieldList() {
        return items.stream()
                .filter(m -> !m.isStatic())
                .map(m -> new FieldInfo(m.name, m.getSize()))
                .collect(Collectors.toList());
    }

    public int getSize() {
        return map.values().stream().mapToInt(MethodOrField::getSize).sum();
    }

    public MethodOrField get(String name) {
        return map.get(name);
    }
}
