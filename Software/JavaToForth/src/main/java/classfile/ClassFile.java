package classfile;

import classfile.attributes.Attributes;
import classfile.constantpool.*;

import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Stack;
import java.util.stream.Collectors;

public final class ClassFile {
    String fileName;
    int minorVersion, majorVersion;
    ConstantPool constantPoolInfo;
    int accessFlags, thisClass, superClass;
    Interfaces interfaceInfo;
    MethodsOrFields fieldsInfo;
    MethodsOrFields methodsInfo;
    Attributes attributesInfo;
    List<MethodName> methods;

    public ClassFile(byte[] data, String fileName) throws ClassFileException {
        this.fileName = fileName;
        System.out.printf("Loading %s...\n", fileName);
        ByteBuffer bb = ByteBuffer.wrap(data);
        var magic = bb.getInt();
        if (magic != 0xCAFEBABE)
            throw new ClassFileException("Invalid magic number: " + magic);
        minorVersion = bb.getShort();
        majorVersion = bb.getShort();
        constantPoolInfo = new ConstantPool(bb);
        accessFlags = bb.getShort();
        thisClass = bb.getShort();
        superClass = bb.getShort();
        interfaceInfo = new Interfaces(bb);
        fieldsInfo = new MethodsOrFields(thisClass, constantPoolInfo, bb);
        methodsInfo = new MethodsOrFields(thisClass, constantPoolInfo, bb);
        attributesInfo = new Attributes(constantPoolInfo, bb);
        if (bb.hasRemaining())
            throw new ClassFileException("class file contains unknown bytes");
        methods = null;
    }

    @Override
    public String toString() {
        return  "  minorVersion: " + minorVersion + "\n" +
                "  majorVersion: " + majorVersion + "\n" +
                "  accessFlags: " + accessFlags + "\n" +
                "  thisClass: " + thisClass + "\n" +
                "  superClass: " + superClass + "\n" +
                constantPoolInfo.toString() + interfaceInfo.toString() + fieldsInfo.toString() +
                methodsInfo.toString() + attributesInfo.toString();
    }

    public Object getFileName() {
        return fileName;
    }

    public String getName() throws ClassFileException {
        return getName(this.thisClass);
    }

    public String getName(int index) throws ClassFileException {
        return constantPoolInfo.getClassName(index);
    }

    public Map<String, MethodOrField> getMethods() {
        return methodsInfo.map;
    }

    public Map<String, MethodOrField> getFields() {
        return fieldsInfo.map;
    }

    public ConstantPoolItem getFromConstantPool(int index) {
        return constantPoolInfo.get(index);
    }

    public String getUtf8Constant(int index) throws ClassFileException {
        return constantPoolInfo.getUtf8Constant(index);
    }

    public String getMethodFullName(int index) throws ClassFileException {
        var item = constantPoolInfo.get(index);
        if (item instanceof MethodReferenceConstantPoolItem mr)
            return mr.getFullName(constantPoolInfo);
        throw new ClassFileException("wrong pool index for getMethodName");
    }

    public String getMethodName(int index) throws ClassFileException {
        var item = constantPoolInfo.get(index);
        if (item instanceof MethodReferenceConstantPoolItem mr)
            return mr.getName(constantPoolInfo);
        throw new ClassFileException("wrong pool index for getMethodName");
    }

    public String getFieldName(int index) throws ClassFileException {
        var item = constantPoolInfo.get(index);
        if (item instanceof FieldReferenceConstantPoolItem fr)
            return fr.getName(constantPoolInfo);
        throw new ClassFileException("wrong pool index for getFieldName");
    }

    public String getMethodClassName(int index) throws ClassFileException {
        var item = constantPoolInfo.get(index);
        if (item instanceof MethodReferenceConstantPoolItem mr)
            return mr.getClassName(constantPoolInfo);
        throw new ClassFileException("wrong pool index for getMethodClassName");
    }

    public int getNumberOfParameters(String name) throws ClassFileException {
        var m = methodsInfo.get(name);
        return m.getNumberOfParameters();
    }

    public int getMethodIndex(String name, Map<String, ClassFile> classes) throws ClassFileException {
        buildMethodNameList(classes);
        for (var i = 0; i < methods.size(); i++) {
            var m = methods.get(i);
            if (m.methodName.equals(name))
                return i;
        }
        throw new ClassFileException("method " + name + " not found");
    }

    public int calculateFieldsSize(Map<String, ClassFile> classes) throws ClassFileException {
        var size = calculateFieldsSize();
        var parent = superClass;
        while (parent != 0) {
            var parentName = getName(parent);
            var parentClass = classes.get(parentName);
            parent = parentClass.superClass;
            size += parentClass.calculateFieldsSize();
        }
        return size;
    }

    private int calculateFieldsSize() {
        return fieldsInfo.getSize();
    }

    public boolean isLongField(int index) throws ClassFileException {
        return constantPoolInfo.isLongField(index);
    }

    public boolean hasMethod(String name) {
        return methodsInfo.hasMethod(name);
    }

    public List<String> buildMethodsList(Map<String, ClassFile> classes) throws ClassFileException {
        buildMethodNameList(classes);
        return methods.stream().map(MethodName::toString).collect(Collectors.toList());
    }

    public void buildMethodNameList(Map<String, ClassFile> classes) throws ClassFileException {
        if (methods != null)
            return;
        Stack<List<MethodName>> methods = new Stack<>();
        methods.push(buildMethodsList());
        var classId = superClass;
        while (classId != 0) {
            var className = getName(classId);
            var classFile = classes.get(className);
            methods.push(classFile.buildMethodsList());
            classId = classFile.superClass;
        }
        this.methods = new ArrayList<MethodName>();
        while (!methods.isEmpty()) {
            var l = methods.pop();
            for (var m : l) {
                var existing = this.methods.stream().filter(r -> r.methodName.equals(m.methodName)).findFirst();
                if (existing.isPresent())
                    existing.get().className = m.className;
                else
                    this.methods.add(m);
            }
        }
    }

    private List<MethodName> buildMethodsList() throws ClassFileException {
        var name = getName();
        return methodsInfo.getList().stream().map(m -> new MethodName(name, m)).toList();
    }

    public List<String> buildParentsList(Map<String, ClassFile> classes) throws ClassFileException {
        var result = new ArrayList<String>();
        var parent = superClass;
        while (parent != 0) {
            var parentName = getName(parent);
            result.add(parentName);
            parent = classes.get(parentName).superClass;
        }
        return result;
    }
}
