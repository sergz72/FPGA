public final class Hal {
    public static final int MS = 1000;
    public static native void ledSet(boolean state);
    public static native void timerStart(int us);
    public static native void wfi();
    public static native void hlt();
}
