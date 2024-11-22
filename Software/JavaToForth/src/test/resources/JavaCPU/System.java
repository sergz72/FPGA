package JavaCPU;

public final class System {
    static int heapPointer = Hal.HEAP_START;

    public static int newObject(int methodsTablePointer, int fieldsSize) {
        int p = heapPointer;
        heapPointer += fieldsSize + 1;
        set(methodsTablePointer, p);
        return p;
    }

    public static int newArray(int size) {
        int p = heapPointer;
        set(size, p);
        heapPointer += size + 1;
        return p;
    }

    public static int newLongArray(int size) {
        int p = heapPointer;
        set(size, p);
        heapPointer += (size << 1) + 1;
        return p;
    }

    public static boolean stringEquals(String s, char[] array, int pos, int l) {
        if (array == null)
            return false;
        char[] ca = s.toCharArray();
        if (ca.length != l)
            return false;
        for (int i = 0; i < l; i++) {
            if (ca[i] != array[i+pos])
                return false;
        }
        return true;
    }

    public native static void set(int v, int p);
    public native static int get(int p);
    public static native void wfi();
    public static native void hlt();
    public static native int getStackPointer();
    public static native int bitTest(int v, int bit);
}
