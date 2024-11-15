public final class System {
    private static int heapPointer = 0x60000000;

    public static int newObject(int size) {
        int p = heapPointer;
        heapPointer += size;
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
}
