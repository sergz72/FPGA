package classfile;

import java.nio.ByteBuffer;

public final class Fields extends ClassFileInfo<FieldsItem> {
    public Fields(ByteBuffer bb) throws ClassFileException {
        super(bb, 0, buffer -> {
            try {
                return new ClassFileInfo.CreatorResult<>(FieldsItem.load(buffer));
            } catch (ClassFileException e) {
                return new ClassFileInfo.CreatorResult<>(e.getMessage());
            }
        });
    }
}
