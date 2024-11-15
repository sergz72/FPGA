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

    private native static void set(int v, int p);
    public static native void wfi();
    public static native void hlt();
}
