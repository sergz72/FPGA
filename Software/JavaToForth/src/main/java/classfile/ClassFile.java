package classfile;

import classfile.attributes.Attributes;
import classfile.constantpool.*;

import java.nio.ByteBuffer;
import java.util.List;
import java.util.Map;

public final class ClassFile {
    String fileName;
    int minorVersion, majorVersion;
    ConstantPool constantPoolInfo;
    int accessFlags, thisClass, superClass;
    Interfaces interfaceInfo;
    MethodsOrFields fieldsInfo;
    MethodsOrFields methodsInfo;
    Attributes attributesInfo;

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

    public int getMethodIndex(int index) {
        throw new UnsupportedOperationException();
    }

    public int calculateFieldsSize(Map<String, ClassFile> classes) {
        throw new UnsupportedOperationException();
    }

    public List<String> buildMethodsList(Map<String, ClassFile> classes) {
        throw new UnsupportedOperationException();
    }

    public boolean isLongField(int index) throws ClassFileException {
        return constantPoolInfo.isLongField(index);
    }

    public boolean hasMethod(String name) {
        return methodsInfo.hasMethod(name);
    }
}
