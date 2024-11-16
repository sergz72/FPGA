package java.lang;

public class Object {
    public native int hashCode();    

    public String toString() {
        return "Object";
    }
    
    public boolean equals(Object obj) {
        return this == obj;
    }
}
