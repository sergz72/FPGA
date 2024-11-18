package java.lang;

public final class String {
    public native char[] toCharArray();

    @Override
    public boolean equals(Object obj) {
        if (obj == null)
            return false;
        if (this == obj)
            return true;
        if (obj instanceof String) {
            char[] c1 = this.toCharArray();
            char[] c2 = ((String)obj).toCharArray();
            if (c1.length != c2.length)
                return false;
            for (int i = 0; i < c1.length; i++) {
                if (c1[i] != c2[i])
                    return false;
            }
            return true;
        }
        return false;
    }
}
