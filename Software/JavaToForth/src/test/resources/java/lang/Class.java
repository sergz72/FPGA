package java.lang;

public class Class<T> {
    private native Class[] getParents();

    private boolean isInstance(Class c) {
        if (this == c)
            return true;
        for (Class parent: c.getParents()) {
            if (isInstance(parent))
                return true;
        }
        return false;
    }

    public boolean isInstance(Object obj) {
        if (obj == null)
            return false;
        return isInstance(obj.getClass());
    }
}
