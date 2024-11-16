package JavaCPU;

public final class Hal {
    static final int HEAP_START = 0x60000000;
    public static final int MS = 1000;
    public static native void ledSet(boolean state);
    public static native void timerStart(int us);

    public static void outChar(char c) {
        while ((uartGet() & 0x100) != 0)
          ;
        uartOut(c);
    }
    
    private static native void uartOut(char c);
    public static native int uartGet();
}
