package classfile;

import classfile.attributes.Attributes;
import classfile.constantpool.ConstantPool;

import java.nio.ByteBuffer;
import java.util.Map;

public final class ClassFile {
    String fileName;
    int minorVersion, majorVersion;
    ConstantPool constantPoolInfo;
    int accessFlags, thisClass, superClass;
    Interfaces interfaceInfo;
    Fields fieldsInfo;
    Methods methodsInfo;
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
        fieldsInfo = new Fields(bb);
        methodsInfo = new Methods(constantPoolInfo, bb);
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

    public String GetName() throws ClassFileException {
        return constantPoolInfo.getClassName(this.thisClass);
    }

    public Map<String, MethodsItem> getMethods() {
        return methodsInfo.methods;
    }
}
