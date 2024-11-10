package classfile;

import java.nio.ByteBuffer;

public final class Interfaces extends ClassFileInfo<InterfacesItem> {
    public Interfaces(ByteBuffer bb) throws ClassFileException {
        super(bb, 0, buffer -> {
            try {
                return new ClassFileInfo.CreatorResult<>(InterfacesItem.load(buffer));
            } catch (ClassFileException e) {
                return new ClassFileInfo.CreatorResult<>(e.getMessage());
            }
        });
    }
}
