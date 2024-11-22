package classfile;

import java.nio.ByteBuffer;

public final class InterfacesItem {
    short classIndex;

    private InterfacesItem(short classIndex) {
        this.classIndex = classIndex;
    }

    static InterfacesItem load(ByteBuffer bb) throws ClassFileException {
        return new InterfacesItem(bb.getShort());
    }
}
