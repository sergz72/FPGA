package java.lang;

public class Object {
    public final native Class<?> getClass();
    public native int hashCode();

    public String toString() {
        return "Object";
    }
    
    public boolean equals(Object obj) {
        return this == obj;
    }
}
