package classfile;

import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.function.Function;

public class ClassFileInfo<T> {
    protected static class CreatorResult<T> {
        T[] values;
        String errorMessage;

        public CreatorResult(T[] items) {
            this.values = items;
        }

        public CreatorResult(String errorMessage) {
            this.errorMessage = errorMessage;
        }
    }

    protected List<T> items;

    protected ClassFileInfo(ByteBuffer bb, int start, Function<ByteBuffer, CreatorResult<T>> creator)
            throws ClassFileException {
        var count = bb.getShort();
        items = new ArrayList<>(count);
        for (var i = start; i < count;) {
            var result = creator.apply(bb);
            if (result.errorMessage != null)
                throw new ClassFileException(result.errorMessage);
            Collections.addAll(items, result.values);
            i += result.values.length;
        }
    }
}
